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
use crate::commands::OutputFile;

pub fn generate_java_code(cache: &Cache) -> Result<OutputFile> {
    let class_elements: Vec<ClassElement> = cache.iter().map(create_class_element).collect();
    let readwrite = class_elements.iter().any(|item| item.readwrite);
    let namespace = uppercase_first_letter(
        cache.iter().find(|item| !item.namespace.is_empty()).unwrap().namespace.as_str(),
    );
    let context = Context { namespace: namespace.clone(), readwrite, class_elements };
    let mut template = TinyTemplate::new();
    template.add_template("java_code_gen", include_str!("../templates/java.template"))?;
    let contents = template.render("java_code_gen", &context)?;
    let path = ["com", "android", "internal", "aconfig", &(namespace + ".java")].iter().collect();
    Ok(OutputFile { contents: contents.into(), path })
}

#[derive(Serialize)]
struct Context {
    pub namespace: String,
    pub readwrite: bool,
    pub class_elements: Vec<ClassElement>,
}

#[derive(Serialize)]
struct ClassElement {
    pub method_name: String,
    pub readwrite: bool,
    pub default_value: String,
    pub feature_name: String,
    pub flag_name: String,
}

fn create_class_element(item: &Item) -> ClassElement {
    ClassElement {
        method_name: item.name.clone(),
        readwrite: item.permission == Permission::ReadWrite,
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
    use crate::aconfig::{FlagDeclaration, FlagValue, FlagState, Permission};
    use crate::commands::Source;

    #[test]
    fn test_generate_java_code() {
        let namespace = "TeSTFlaG";
        let mut cache = Cache::new(namespace.to_string());
        cache
            .add_flag_declaration(
                Source::File("test.txt".to_string()),
                FlagDeclaration {
                    name: "test".to_string(),
                    description: "buildtime enable".to_string(),
                },
            )
            .unwrap();
        cache
            .add_flag_declaration(
                Source::File("test2.txt".to_string()),
                FlagDeclaration {
                    name: "test2".to_string(),
                    description: "runtime disable".to_string(),
                },
            )
            .unwrap();
        cache
            .add_flag_value(
                Source::Memory,
                FlagValue {
                    namespace: namespace.to_string(),
                    name: "test".to_string(),
                    state: FlagState::Disabled,
                    permission: Permission::ReadOnly,
                },
            )
            .unwrap();
        let expect_content = r#"package com.android.internal.aconfig;

        import android.provider.DeviceConfig;

        public final class Testflag {

            public static boolean test() {
                return false;
            }

            public static boolean test2() {
                return DeviceConfig.getBoolean(
                    "Testflag",
                    "test2__test2",
                    false
                );
            }

        }
        "#;
        let file = generate_java_code(&cache).unwrap();
        assert_eq!("com/android/internal/aconfig/Testflag.java", file.path.to_str().unwrap());
        assert_eq!(
            expect_content.replace(' ', ""),
            String::from_utf8(file.contents).unwrap().replace(' ', "")
        );
    }
}
