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

use anyhow::{bail, ensure, Result};
use serde::{Deserialize, Serialize};
use std::io::{Read, Write};

use crate::aconfig::{FlagDeclaration, FlagState, FlagValue, Permission};
use crate::codegen;
use crate::commands::Source;

const DEFAULT_FLAG_STATE: FlagState = FlagState::Disabled;
const DEFAULT_FLAG_PERMISSION: Permission = Permission::ReadWrite;

#[derive(Serialize, Deserialize, Debug)]
pub struct Tracepoint {
    pub source: Source,
    pub state: FlagState,
    pub permission: Permission,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Item {
    // TODO: duplicating the Cache.package as Item.package makes the internal representation
    // closer to the proto message `parsed_flag`; hopefully this will enable us to replace the Item
    // struct and use a newtype instead once aconfig has matured. Until then, package should
    // really be a Cow<String>.
    pub package: String,
    pub name: String,
    pub description: String,
    pub state: FlagState,
    pub permission: Permission,
    pub trace: Vec<Tracepoint>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Cache {
    package: String,
    items: Vec<Item>,
}

// TODO: replace this function with Iterator.is_sorted_by_key(...)) when that API becomes stable
fn iter_is_sorted_by_key<'a, T: 'a, F, K>(iter: impl Iterator<Item = &'a T>, f: F) -> bool
where
    F: FnMut(&'a T) -> K,
    K: PartialOrd<K>,
{
    let mut last: Option<K> = None;
    for current in iter.map(f) {
        if let Some(l) = last {
            if l > current {
                return false;
            }
        }
        last = Some(current);
    }
    true
}

impl Cache {
    pub fn read_from_reader(reader: impl Read) -> Result<Cache> {
        let cache: Cache = serde_json::from_reader(reader)?;
        ensure!(
            iter_is_sorted_by_key(cache.iter(), |item| &item.name),
            "internal error: flags in cache file not sorted"
        );
        Ok(cache)
    }

    pub fn write_to_writer(&self, writer: impl Write) -> Result<()> {
        ensure!(
            iter_is_sorted_by_key(self.iter(), |item| &item.name),
            "internal error: flags in cache file not sorted"
        );
        serde_json::to_writer(writer, self).map_err(|e| e.into())
    }

    pub fn iter(&self) -> impl Iterator<Item = &Item> {
        self.items.iter()
    }

    pub fn into_iter(self) -> impl Iterator<Item = Item> {
        self.items.into_iter()
    }

    pub fn package(&self) -> &str {
        debug_assert!(!self.package.is_empty());
        &self.package
    }
}

#[derive(Debug)]
pub struct CacheBuilder {
    cache: Cache,
}

impl CacheBuilder {
    pub fn new(package: String) -> Result<CacheBuilder> {
        ensure!(codegen::is_valid_package_ident(&package), "bad package");
        let cache = Cache { package, items: vec![] };
        Ok(CacheBuilder { cache })
    }

    pub fn add_flag_declaration(
        &mut self,
        source: Source,
        declaration: FlagDeclaration,
    ) -> Result<&mut CacheBuilder> {
        ensure!(codegen::is_valid_name_ident(&declaration.name), "bad flag name");
        ensure!(!declaration.description.is_empty(), "empty flag description");
        ensure!(
            self.cache.items.iter().all(|item| item.name != declaration.name),
            "failed to declare flag {} from {}: flag already declared",
            declaration.name,
            source
        );
        self.cache.items.push(Item {
            package: self.cache.package.clone(),
            name: declaration.name.clone(),
            description: declaration.description,
            state: DEFAULT_FLAG_STATE,
            permission: DEFAULT_FLAG_PERMISSION,
            trace: vec![Tracepoint {
                source,
                state: DEFAULT_FLAG_STATE,
                permission: DEFAULT_FLAG_PERMISSION,
            }],
        });
        Ok(self)
    }

    pub fn add_flag_value(
        &mut self,
        source: Source,
        value: FlagValue,
    ) -> Result<&mut CacheBuilder> {
        ensure!(codegen::is_valid_package_ident(&value.package), "bad flag package");
        ensure!(codegen::is_valid_name_ident(&value.name), "bad flag name");
        ensure!(
            value.package == self.cache.package,
            "failed to set values for flag {}/{} from {}: expected package {}",
            value.package,
            value.name,
            source,
            self.cache.package
        );
        let Some(existing_item) = self.cache.items.iter_mut().find(|item| item.name == value.name) else {
            bail!("failed to set values for flag {}/{} from {}: flag not declared", value.package, value.name, source);
        };
        existing_item.state = value.state;
        existing_item.permission = value.permission;
        existing_item.trace.push(Tracepoint {
            source,
            state: value.state,
            permission: value.permission,
        });
        Ok(self)
    }

    pub fn build(mut self) -> Cache {
        self.cache.items.sort_by_cached_key(|item| item.name.clone());
        self.cache
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add_flag_declaration() {
        let mut builder = CacheBuilder::new("com.example".to_string()).unwrap();
        builder
            .add_flag_declaration(
                Source::File("first.txt".to_string()),
                FlagDeclaration { name: "foo".to_string(), description: "desc".to_string() },
            )
            .unwrap();
        let error = builder
            .add_flag_declaration(
                Source::File("second.txt".to_string()),
                FlagDeclaration { name: "foo".to_string(), description: "desc".to_string() },
            )
            .unwrap_err();
        assert_eq!(
            &format!("{:?}", error),
            "failed to declare flag foo from second.txt: flag already declared"
        );
        builder
            .add_flag_declaration(
                Source::File("first.txt".to_string()),
                FlagDeclaration { name: "bar".to_string(), description: "desc".to_string() },
            )
            .unwrap();

        let cache = builder.build();

        // check flags are sorted by name
        assert_eq!(
            cache.into_iter().map(|item| item.name).collect::<Vec<_>>(),
            vec!["bar".to_string(), "foo".to_string()]
        );
    }

    #[test]
    fn test_add_flag_value() {
        let mut builder = CacheBuilder::new("com.example".to_string()).unwrap();
        let error = builder
            .add_flag_value(
                Source::Memory,
                FlagValue {
                    package: "com.example".to_string(),
                    name: "foo".to_string(),
                    state: FlagState::Enabled,
                    permission: Permission::ReadOnly,
                },
            )
            .unwrap_err();
        assert_eq!(
            &format!("{:?}", error),
            "failed to set values for flag com.example/foo from <memory>: flag not declared"
        );

        builder
            .add_flag_declaration(
                Source::File("first.txt".to_string()),
                FlagDeclaration { name: "foo".to_string(), description: "desc".to_string() },
            )
            .unwrap();

        builder
            .add_flag_value(
                Source::Memory,
                FlagValue {
                    package: "com.example".to_string(),
                    name: "foo".to_string(),
                    state: FlagState::Disabled,
                    permission: Permission::ReadOnly,
                },
            )
            .unwrap();

        builder
            .add_flag_value(
                Source::Memory,
                FlagValue {
                    package: "com.example".to_string(),
                    name: "foo".to_string(),
                    state: FlagState::Enabled,
                    permission: Permission::ReadWrite,
                },
            )
            .unwrap();

        // different package -> no-op
        let error = builder
            .add_flag_value(
                Source::Memory,
                FlagValue {
                    package: "some_other_package".to_string(),
                    name: "foo".to_string(),
                    state: FlagState::Enabled,
                    permission: Permission::ReadOnly,
                },
            )
            .unwrap_err();
        assert_eq!(&format!("{:?}", error), "failed to set values for flag some_other_package/foo from <memory>: expected package com.example");

        let cache = builder.build();
        let item = cache.iter().find(|&item| item.name == "foo").unwrap();
        assert_eq!(FlagState::Enabled, item.state);
        assert_eq!(Permission::ReadWrite, item.permission);
    }

    #[test]
    fn test_reject_empty_cache_package() {
        CacheBuilder::new("".to_string()).unwrap_err();
    }

    #[test]
    fn test_reject_empty_flag_declaration_fields() {
        let mut builder = CacheBuilder::new("com.example".to_string()).unwrap();

        let error = builder
            .add_flag_declaration(
                Source::Memory,
                FlagDeclaration { name: "".to_string(), description: "Description".to_string() },
            )
            .unwrap_err();
        assert_eq!(&format!("{:?}", error), "bad flag name");

        let error = builder
            .add_flag_declaration(
                Source::Memory,
                FlagDeclaration { name: "foo".to_string(), description: "".to_string() },
            )
            .unwrap_err();
        assert_eq!(&format!("{:?}", error), "empty flag description");
    }

    #[test]
    fn test_reject_empty_flag_value_files() {
        let mut builder = CacheBuilder::new("com.example".to_string()).unwrap();
        builder
            .add_flag_declaration(
                Source::Memory,
                FlagDeclaration { name: "foo".to_string(), description: "desc".to_string() },
            )
            .unwrap();

        let error = builder
            .add_flag_value(
                Source::Memory,
                FlagValue {
                    package: "".to_string(),
                    name: "foo".to_string(),
                    state: FlagState::Enabled,
                    permission: Permission::ReadOnly,
                },
            )
            .unwrap_err();
        assert_eq!(&format!("{:?}", error), "bad flag package");

        let error = builder
            .add_flag_value(
                Source::Memory,
                FlagValue {
                    package: "com.example".to_string(),
                    name: "".to_string(),
                    state: FlagState::Enabled,
                    permission: Permission::ReadOnly,
                },
            )
            .unwrap_err();
        assert_eq!(&format!("{:?}", error), "bad flag name");
    }

    #[test]
    fn test_iter_is_sorted_by_key() {
        assert!(iter_is_sorted_by_key(["a", "b", "c"].iter(), |s| s));
        assert!(iter_is_sorted_by_key(Vec::<&str>::new().iter(), |s| s));
        assert!(!iter_is_sorted_by_key(["a", "c", "b"].iter(), |s| s));
    }
}
