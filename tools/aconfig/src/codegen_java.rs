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

pub struct GeneratedFile {
    pub file_content: String,
    pub file_name: String,
}

pub fn generate_java_code(cache: &Cache) -> Result<GeneratedFile> {
    let class_elements: Vec<ClassElement> =
        cache.iter().map(|item| create_class_element(item)).collect();
    let readonly = class_elements.iter().any(|item| item.readonly);
    let namespace = uppercase_first_letter(
        cache.iter().find(|item| !item.namespace.is_empty()).unwrap().namespace.as_str(),
    );
    let context = Context { namespace: namespace.clone(), readonly, class_elements };
    let mut template = TinyTemplate::new();
    template.add_template("java_code_gen", include_str!("../templates/java.template"))?;
    let file_content = template.render("java_code_gen", &context)?;
    Ok(GeneratedFile { file_content: file_content, file_name: format!("{}.java", namespace) })
}

#[derive(Serialize)]
struct Context {
    pub namespace: String,
    pub readonly: bool,
    pub class_elements: Vec<ClassElement>,
}

#[derive(Serialize)]
struct ClassElement {
    pub method_name: String,
    pub readonly: bool,
    pub default_value: String,
    pub feature_name: String,
    pub flag_name: String,
}

fn create_class_element(item: &Item) -> ClassElement {
    ClassElement {
        method_name: item.name.clone(),
        readonly: if item.permission == Permission::ReadOnly { true } else { false },
        default_value: if item.state == FlagState::Enabled {
            "true".to_string()
        } else {
            "false".to_string()
        },
        feature_name: item.name.clone(),
        flag_name: item.name.clone(),
    }
}

fn uppercase_first_letter(s: &str) -> String {
    s.chars()
        .enumerate()
        .map(
            |(index, ch)| {
                if index == 0 {
                    ch.to_ascii_uppercase()
                } else {
                    ch.to_ascii_lowercase()
                }
            },
        )
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::aconfig::{Flag, Value};
    use crate::commands::Source;

    #[test]
    fn test_generate_java_code() {
        let namespace = "TeSTFlaG";
        let mut cache = Cache::new(1, namespace.to_string());
        cache
            .add_flag(
                Source::File("test.txt".to_string()),
                Flag {
                    name: "test".to_string(),
                    description: "buildtime enable".to_string(),
                    values: vec![Value::default(FlagState::Enabled, Permission::ReadOnly)],
                },
            )
            .unwrap();
        cache
            .add_flag(
                Source::File("test2.txt".to_string()),
                Flag {
                    name: "test2".to_string(),
                    description: "runtime disable".to_string(),
                    values: vec![Value::default(FlagState::Disabled, Permission::ReadWrite)],
                },
            )
            .unwrap();
        let expect_content = "package com.android.aconfig.Testflag;

        import android.provider.DeviceConfig;
        
        public final class Testflag {

            public static boolean test() {
                return true;
            }

            public static boolean test2() {
                return DeviceConfig.getBoolean(
                    \"Testflag\",
                    \"test2__test2\",
                    false
                );
            }

        }
        ";
        let expected_file_name = format!("{}.java", uppercase_first_letter(namespace));
        let generated_file = generate_java_code(&cache).unwrap();
        assert_eq!(expected_file_name, generated_file.file_name);
        assert_eq!(expect_content.replace(' ', ""), generated_file.file_content.replace(' ', ""));
    }
}
