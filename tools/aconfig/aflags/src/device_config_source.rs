/*
 * Copyright (C) 2024 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

use crate::{AconfigDefinition, Flag, FlagPermission, FlagSource, FlagState, FlagValue};
use aconfig_protos::ProtoFlagPermission as ProtoPermission;
use aconfig_protos::ProtoFlagState as ProtoState;
use aconfig_protos::ProtoParsedFlag;
use aconfig_protos::ProtoParsedFlags;
use anyhow::{anyhow, bail, Result};
use regex::Regex;
use std::collections::BTreeMap;
use std::collections::HashMap;
use std::process::Command;
use std::{fs, str};

pub struct DeviceConfigSource {}

fn convert_definition(flag: &ProtoParsedFlag) -> AconfigDefinition {
    let state = match flag.state() {
        ProtoState::ENABLED => FlagState::Enabled,
        ProtoState::DISABLED => FlagState::Disabled,
    };
    let permission = match flag.permission() {
        ProtoPermission::READ_ONLY => FlagPermission::ReadOnly,
        ProtoPermission::READ_WRITE => FlagPermission::ReadWrite,
    };
    AconfigDefinition { state, permission }
}

fn convert_parsed_flag(flag: &ProtoParsedFlag) -> Flag {
    let namespace = flag.namespace().to_string();
    let package = flag.package().to_string();
    let name = flag.name().to_string();

    let container = flag.container().to_string();
    let container = if !container.is_empty() { container } else { "system".to_string() };

    Flag {
        namespace,
        package,
        name,
        container: Some(container),
        value: FlagValue::DefaultValue("<not set>".to_string()),
        definitions: HashMap::new(),
        permission: FlagPermission::ReadOnly,
    }
}

fn apply_pb_default(flag: Flag) -> Result<Flag> {
    let definition = flag
        .definitions
        .get(&flag.clone().container.unwrap_or("system".to_string()))
        .ok_or(anyhow!("no definition for flag"))?;
    let value = definition.state.to_string();
    let permission = &definition.permission;

    Ok(Flag { value: FlagValue::DefaultValue(value), permission: permission.clone(), ..flag })
}

fn read_pb_files() -> Result<Vec<Flag>> {
    let mut flags: BTreeMap<String, Flag> = BTreeMap::new();
    for partition in ["system", "system_ext", "product", "vendor"] {
        let path = format!("/{}/etc/aconfig_flags.pb", partition);
        let Ok(bytes) = fs::read(&path) else {
            eprintln!("warning: failed to read {}", path);
            continue;
        };
        let parsed_flags: ProtoParsedFlags = protobuf::Message::parse_from_bytes(&bytes)?;
        for flag in parsed_flags.parsed_flag {
            let key = format!("{}.{}", flag.package(), flag.name());
            let container = flag.container().to_string();
            let container = if container.is_empty() { "system".to_string() } else { container };
            flags
                .entry(key)
                .or_insert(convert_parsed_flag(&flag))
                .definitions
                .insert(container, convert_definition(&flag));
        }
    }
    Ok(flags.values().cloned().collect())
}

fn parse_device_config(raw: &str) -> HashMap<String, String> {
    let mut flags = HashMap::new();
    let regex = Regex::new(r"(?m)^([[[:alnum:]]_]+/[[[:alnum:]]_\.]+)=(true|false)$").unwrap();
    for capture in regex.captures_iter(raw) {
        let key = capture.get(1).unwrap().as_str().to_string();
        let value = match capture.get(2).unwrap().as_str() {
            "true" => FlagState::Enabled.to_string(),
            "false" => FlagState::Disabled.to_string(),
            _ => panic!(),
        };
        flags.insert(key, value);
    }
    flags
}

fn read_device_config_output(command: &str) -> Result<String> {
    let output = Command::new("/system/bin/device_config").arg(command).output()?;
    if !output.status.success() {
        let reason = match output.status.code() {
            Some(code) => format!("exit code {}", code),
            None => "terminated by signal".to_string(),
        };
        bail!("failed to execute device_config: {}", reason);
    }
    Ok(str::from_utf8(&output.stdout)?.to_string())
}

fn read_device_config_flags() -> Result<HashMap<String, String>> {
    let list_output = read_device_config_output("list")?;
    let flags = parse_device_config(&list_output);
    Ok(flags)
}

fn reconcile(pb_flags: &[Flag], dc_flags: HashMap<String, String>) -> Vec<Flag> {
    pb_flags
        .iter()
        .map(|f| {
            dc_flags
                .get(&format!("{}/{}.{}", f.namespace, f.package, f.name))
                .map(|value| {
                    if value.eq(&f.value.display_value()) {
                        Flag { value: FlagValue::DefaultValue(value.to_string()), ..f.clone() }
                    } else {
                        Flag { value: FlagValue::ServerValue(value.to_string()), ..f.clone() }
                    }
                })
                .unwrap_or(f.clone())
        })
        .collect()
}

impl FlagSource for DeviceConfigSource {
    fn list_flags() -> Result<Vec<Flag>> {
        let pb_flags = read_pb_files()?
            .iter()
            .map(|f| apply_pb_default(f.clone()))
            .collect::<Result<Vec<Flag>>>()?;
        let dc_flags = read_device_config_flags()?;

        let flags = reconcile(&pb_flags, dc_flags);
        Ok(flags)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_device_config() {
        let input = r#"
namespace_one/com.foo.bar.flag_one=true
namespace_one/com.foo.bar.flag_two=false
random_noise;
namespace_two/android.flag_one=true
namespace_two/android.flag_two=nonsense
"#;
        let expected = HashMap::from([
            ("namespace_one/com.foo.bar.flag_one".to_string(), "T".to_string()),
            ("namespace_one/com.foo.bar.flag_two".to_string(), "F".to_string()),
            ("namespace_two/android.flag_one".to_string(), "T".to_string()),
        ]);
        let actual = parse_device_config(input);
        assert_eq!(expected, actual);
    }
}
