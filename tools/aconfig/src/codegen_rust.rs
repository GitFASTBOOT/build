/*
 * Copyright (C) 2023 The Android Open Source Project
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

use anyhow::Result;
use serde::Serialize;
use tinytemplate::TinyTemplate;

use crate::aconfig::{FlagState, Permission};
use crate::cache::{Cache, Item};
use crate::codegen;
use crate::commands::OutputFile;

pub fn generate_rust_code(cache: &Cache) -> Result<OutputFile> {
    let package = cache.package();
    let parsed_flags: Vec<TemplateParsedFlag> =
        cache.iter().map(|item| TemplateParsedFlag::new(package, item)).collect();
    let context = TemplateContext {
        package: package.to_string(),
        parsed_flags,
        modules: package.split('.').map(|s| s.to_string()).collect::<Vec<_>>(),
    };
    let mut template = TinyTemplate::new();
    template.add_template("rust_code_gen", include_str!("../templates/rust.template"))?;
    let contents = template.render("rust_code_gen", &context)?;
    let path = ["src", "lib.rs"].iter().collect();
    Ok(OutputFile { contents: contents.into(), path })
}

#[derive(Serialize)]
struct TemplateContext {
    pub package: String,
    pub parsed_flags: Vec<TemplateParsedFlag>,
    pub modules: Vec<String>,
}

#[derive(Serialize)]
struct TemplateParsedFlag {
    pub name: String,
    pub device_config_namespace: String,
    pub device_config_flag: String,

    // TinyTemplate's conditionals are limited to single <bool> expressions; list all options here
    // Invariant: exactly one of these fields will be true
    pub is_read_only_enabled: bool,
    pub is_read_only_disabled: bool,
    pub is_read_write: bool,
}

impl TemplateParsedFlag {
    #[allow(clippy::nonminimal_bool)]
    fn new(package: &str, item: &Item) -> Self {
        let template = TemplateParsedFlag {
            name: item.name.clone(),
            device_config_namespace: item.namespace.to_string(),
            device_config_flag: codegen::create_device_config_ident(package, &item.name)
                .expect("values checked at cache creation time"),
            is_read_only_enabled: item.permission == Permission::ReadOnly
                && item.state == FlagState::Enabled,
            is_read_only_disabled: item.permission == Permission::ReadOnly
                && item.state == FlagState::Disabled,
            is_read_write: item.permission == Permission::ReadWrite,
        };
        #[rustfmt::skip]
        debug_assert!(
            (template.is_read_only_enabled && !template.is_read_only_disabled && !template.is_read_write) ||
            (!template.is_read_only_enabled && template.is_read_only_disabled && !template.is_read_write) ||
            (!template.is_read_only_enabled && !template.is_read_only_disabled && template.is_read_write),
            "TemplateParsedFlag invariant failed: {} {} {}",
            template.is_read_only_enabled,
            template.is_read_only_disabled,
            template.is_read_write,
        );
        template
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_rust_code() {
        let cache = crate::test::create_cache();
        let generated = generate_rust_code(&cache).unwrap();
        assert_eq!("src/lib.rs", format!("{}", generated.path.display()));
        let expected = r#"
pub mod com {
pub mod android {
pub mod aconfig {
pub mod test {
#[inline(always)]
pub const fn r#disabled_ro() -> bool {
    false
}

#[inline(always)]
pub fn r#disabled_rw() -> bool {
    flags_rust::GetServerConfigurableFlag("aconfig_test", "com.android.aconfig.test.disabled_rw", "false") == "true"
}

#[inline(always)]
pub const fn r#enabled_ro() -> bool {
    true
}

#[inline(always)]
pub fn r#enabled_rw() -> bool {
    flags_rust::GetServerConfigurableFlag("aconfig_test", "com.android.aconfig.test.enabled_rw", "false") == "true"
}

}
}
}
}
"#;
        assert_eq!(expected.trim(), String::from_utf8(generated.contents).unwrap().trim());
    }
}
