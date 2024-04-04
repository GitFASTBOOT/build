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

//! `aconfig_storage_file` is a crate that defines aconfig storage file format, it
//! also includes apis to read flags from storage files. It provides three apis to
//! interface with storage files:
//!
//! 1, function to get package flag value start offset
//! pub fn get_package_offset(container: &str, package: &str) -> `Result<Option<PackageOffset>>>`
//!
//! 2, function to get flag offset within a specific package
//! pub fn get_flag_offset(container: &str, package_id: u32, flag: &str) -> `Result<Option<u16>>>`
//!
//! 3, function to get the actual flag value given the global offset (combined package and
//! flag offset).
//! pub fn get_boolean_flag_value(container: &str, offset: u32) -> `Result<bool>`
//!
//! Note these are low level apis that are expected to be only used in auto generated flag
//! apis. DO NOT DIRECTLY USE THESE APIS IN YOUR SOURCE CODE. For auto generated flag apis
//! please refer to the g3doc go/android-flags

pub mod flag_info;
pub mod flag_table;
pub mod flag_value;
pub mod package_table;
pub mod protos;
pub mod test_utils;

use anyhow::anyhow;
use std::cmp::Ordering;
use std::collections::hash_map::DefaultHasher;
use std::fs::File;
use std::hash::{Hash, Hasher};
use std::io::{Read, Write};

pub use crate::flag_info::{FlagInfoHeader, FlagInfoList, FlagInfoNode};
pub use crate::flag_table::{FlagTable, FlagTableHeader, FlagTableNode};
pub use crate::flag_value::{FlagValueHeader, FlagValueList};
pub use crate::package_table::{PackageTable, PackageTableHeader, PackageTableNode};

use crate::AconfigStorageError::{
    BytesParseFail, FileCreationFail, HashTableSizeLimit, InvalidStoredFlagType,
};

/// Storage file version
pub const FILE_VERSION: u32 = 1;

/// Good hash table prime number
pub(crate) const HASH_PRIMES: [u32; 29] = [
    7, 17, 29, 53, 97, 193, 389, 769, 1543, 3079, 6151, 12289, 24593, 49157, 98317, 196613, 393241,
    786433, 1572869, 3145739, 6291469, 12582917, 25165843, 50331653, 100663319, 201326611,
    402653189, 805306457, 1610612741,
];

/// Storage file type enum
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum StorageFileType {
    PackageMap = 0,
    FlagMap = 1,
    FlagVal = 2,
    FlagInfo = 3,
}

impl TryFrom<&str> for StorageFileType {
    type Error = anyhow::Error;

    fn try_from(value: &str) -> std::result::Result<Self, Self::Error> {
        match value {
            "package_map" => Ok(Self::PackageMap),
            "flag_map" => Ok(Self::FlagMap),
            "flag_val" => Ok(Self::FlagVal),
            "flag_info" => Ok(Self::FlagInfo),
            _ => Err(anyhow!(
                "Invalid storage file type, valid types are package_map|flag_map|flag_val|flag_info"
            )),
        }
    }
}

impl TryFrom<u8> for StorageFileType {
    type Error = anyhow::Error;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value {
            x if x == Self::PackageMap as u8 => Ok(Self::PackageMap),
            x if x == Self::FlagMap as u8 => Ok(Self::FlagMap),
            x if x == Self::FlagVal as u8 => Ok(Self::FlagVal),
            x if x == Self::FlagInfo as u8 => Ok(Self::FlagInfo),
            _ => Err(anyhow!("Invalid storage file type")),
        }
    }
}

/// Flag type enum as stored by storage file
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum StoredFlagType {
    ReadWriteBoolean = 0,
    ReadOnlyBoolean = 1,
    FixedReadOnlyBoolean = 2,
}

impl TryFrom<u16> for StoredFlagType {
    type Error = AconfigStorageError;

    fn try_from(value: u16) -> Result<Self, Self::Error> {
        match value {
            x if x == Self::ReadWriteBoolean as u16 => Ok(Self::ReadWriteBoolean),
            x if x == Self::ReadOnlyBoolean as u16 => Ok(Self::ReadOnlyBoolean),
            x if x == Self::FixedReadOnlyBoolean as u16 => Ok(Self::FixedReadOnlyBoolean),
            _ => Err(InvalidStoredFlagType(anyhow!("Invalid stored flag type"))),
        }
    }
}

/// Storage query api error
#[non_exhaustive]
#[derive(thiserror::Error, Debug)]
pub enum AconfigStorageError {
    #[error("failed to read the file")]
    FileReadFail(#[source] anyhow::Error),

    #[error("fail to parse protobuf")]
    ProtobufParseFail(#[source] anyhow::Error),

    #[error("storage files not found for this container")]
    StorageFileNotFound(#[source] anyhow::Error),

    #[error("fail to map storage file")]
    MapFileFail(#[source] anyhow::Error),

    #[error("fail to get mapped file")]
    ObtainMappedFileFail(#[source] anyhow::Error),

    #[error("fail to flush mapped storage file")]
    MapFlushFail(#[source] anyhow::Error),

    #[error("number of items in hash table exceed limit")]
    HashTableSizeLimit(#[source] anyhow::Error),

    #[error("failed to parse bytes into data")]
    BytesParseFail(#[source] anyhow::Error),

    #[error("cannot parse storage files with a higher version")]
    HigherStorageFileVersion(#[source] anyhow::Error),

    #[error("invalid storage file byte offset")]
    InvalidStorageFileOffset(#[source] anyhow::Error),

    #[error("failed to create file")]
    FileCreationFail(#[source] anyhow::Error),

    #[error("invalid stored flag type")]
    InvalidStoredFlagType(#[source] anyhow::Error),
}

/// Get the right hash table size given number of entries in the table. Use a
/// load factor of 0.5 for performance.
pub fn get_table_size(entries: u32) -> Result<u32, AconfigStorageError> {
    HASH_PRIMES
        .iter()
        .find(|&&num| num >= 2 * entries)
        .copied()
        .ok_or(HashTableSizeLimit(anyhow!("Number of items in a hash table exceeds limit")))
}

/// Get the corresponding bucket index given the key and number of buckets
pub(crate) fn get_bucket_index<T: Hash>(val: &T, num_buckets: u32) -> u32 {
    let mut s = DefaultHasher::new();
    val.hash(&mut s);
    (s.finish() % num_buckets as u64) as u32
}

/// Read and parse bytes as u8
pub fn read_u8_from_bytes(buf: &[u8], head: &mut usize) -> Result<u8, AconfigStorageError> {
    let val =
        u8::from_le_bytes(buf[*head..*head + 1].try_into().map_err(|errmsg| {
            BytesParseFail(anyhow!("fail to parse u8 from bytes: {}", errmsg))
        })?);
    *head += 1;
    Ok(val)
}

/// Read and parse bytes as u16
pub(crate) fn read_u16_from_bytes(
    buf: &[u8],
    head: &mut usize,
) -> Result<u16, AconfigStorageError> {
    let val =
        u16::from_le_bytes(buf[*head..*head + 2].try_into().map_err(|errmsg| {
            BytesParseFail(anyhow!("fail to parse u16 from bytes: {}", errmsg))
        })?);
    *head += 2;
    Ok(val)
}

/// Read and parse bytes as u32
pub fn read_u32_from_bytes(buf: &[u8], head: &mut usize) -> Result<u32, AconfigStorageError> {
    let val =
        u32::from_le_bytes(buf[*head..*head + 4].try_into().map_err(|errmsg| {
            BytesParseFail(anyhow!("fail to parse u32 from bytes: {}", errmsg))
        })?);
    *head += 4;
    Ok(val)
}

/// Read and parse bytes as string
pub(crate) fn read_str_from_bytes(
    buf: &[u8],
    head: &mut usize,
) -> Result<String, AconfigStorageError> {
    let num_bytes = read_u32_from_bytes(buf, head)? as usize;
    let val = String::from_utf8(buf[*head..*head + num_bytes].to_vec())
        .map_err(|errmsg| BytesParseFail(anyhow!("fail to parse string from bytes: {}", errmsg)))?;
    *head += num_bytes;
    Ok(val)
}

/// Read in storage file as bytes
pub fn read_file_to_bytes(file_path: &str) -> Result<Vec<u8>, AconfigStorageError> {
    let mut file = File::open(file_path).map_err(|errmsg| {
        AconfigStorageError::FileReadFail(anyhow!("Failed to open file {}: {}", file_path, errmsg))
    })?;
    let mut buffer = Vec::new();
    file.read_to_end(&mut buffer).map_err(|errmsg| {
        AconfigStorageError::FileReadFail(anyhow!(
            "Failed to read bytes from file {}: {}",
            file_path,
            errmsg
        ))
    })?;
    Ok(buffer)
}

/// List flag values from storage files
pub fn list_flags(
    package_map: &str,
    flag_map: &str,
    flag_val: &str,
) -> Result<Vec<(String, String, StoredFlagType, bool)>, AconfigStorageError> {
    let package_table = PackageTable::from_bytes(&read_file_to_bytes(package_map)?)?;
    let flag_table = FlagTable::from_bytes(&read_file_to_bytes(flag_map)?)?;
    let flag_value_list = FlagValueList::from_bytes(&read_file_to_bytes(flag_val)?)?;

    let mut package_info = vec![("", 0); package_table.header.num_packages as usize];
    for node in package_table.nodes.iter() {
        package_info[node.package_id as usize] = (&node.package_name, node.boolean_offset);
    }

    let mut flags = Vec::new();
    for node in flag_table.nodes.iter() {
        let (package_name, package_offset) = package_info[node.package_id as usize];
        let flag_offset = package_offset + node.flag_id as u32;
        let flag_value = flag_value_list.booleans[flag_offset as usize];
        flags.push((
            String::from(package_name),
            node.flag_name.clone(),
            node.flag_type,
            flag_value,
        ));
    }

    flags.sort_by(|v1, v2| match v1.0.cmp(&v2.0) {
        Ordering::Equal => v1.1.cmp(&v2.1),
        other => other,
    });
    Ok(flags)
}

/// Create flag info file
pub fn create_flag_info(
    package_map: &str,
    flag_map: &str,
    flag_info_out: &str,
) -> Result<(), AconfigStorageError> {
    let package_table = PackageTable::from_bytes(&read_file_to_bytes(package_map)?)?;
    let flag_table = FlagTable::from_bytes(&read_file_to_bytes(flag_map)?)?;

    if package_table.header.container != flag_table.header.container {
        return Err(FileCreationFail(anyhow!(
            "container for package map {} and flag map {} does not match",
            package_table.header.container,
            flag_table.header.container,
        )));
    }

    let mut package_offsets = vec![0; package_table.header.num_packages as usize];
    for node in package_table.nodes.iter() {
        package_offsets[node.package_id as usize] = node.boolean_offset;
    }

    let mut is_flag_rw = vec![false; flag_table.header.num_flags as usize];
    for node in flag_table.nodes.iter() {
        let flag_offset = package_offsets[node.package_id as usize] + node.flag_id as u32;
        is_flag_rw[flag_offset as usize] = node.flag_type == StoredFlagType::ReadWriteBoolean;
    }

    let mut list = FlagInfoList {
        header: FlagInfoHeader {
            version: FILE_VERSION,
            container: flag_table.header.container,
            file_type: StorageFileType::FlagInfo as u8,
            file_size: 0,
            num_flags: flag_table.header.num_flags,
            boolean_flag_offset: 0,
        },
        nodes: is_flag_rw.iter().map(|&rw| FlagInfoNode::create(rw)).collect(),
    };

    list.header.boolean_flag_offset = list.header.into_bytes().len() as u32;
    list.header.file_size = list.into_bytes().len() as u32;

    let mut file = File::create(flag_info_out).map_err(|errmsg| {
        FileCreationFail(anyhow!("fail to create file {}: {}", flag_info_out, errmsg))
    })?;
    file.write_all(&list.into_bytes()).map_err(|errmsg| {
        FileCreationFail(anyhow!("fail to write to file {}: {}", flag_info_out, errmsg))
    })?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_utils::{
        create_test_flag_info_list, create_test_flag_table, create_test_flag_value_list,
        create_test_package_table, write_bytes_to_temp_file,
    };
    use tempfile::NamedTempFile;

    #[test]
    // this test point locks down the flag list api
    fn test_list_flag() {
        let package_table =
            write_bytes_to_temp_file(&create_test_package_table().into_bytes()).unwrap();
        let flag_table = write_bytes_to_temp_file(&create_test_flag_table().into_bytes()).unwrap();
        let flag_value_list =
            write_bytes_to_temp_file(&create_test_flag_value_list().into_bytes()).unwrap();

        let package_table_path = package_table.path().display().to_string();
        let flag_table_path = flag_table.path().display().to_string();
        let flag_value_list_path = flag_value_list.path().display().to_string();

        let flags =
            list_flags(&package_table_path, &flag_table_path, &flag_value_list_path).unwrap();
        let expected = [
            (
                String::from("com.android.aconfig.storage.test_1"),
                String::from("disabled_rw"),
                StoredFlagType::ReadWriteBoolean,
                false,
            ),
            (
                String::from("com.android.aconfig.storage.test_1"),
                String::from("enabled_ro"),
                StoredFlagType::ReadOnlyBoolean,
                true,
            ),
            (
                String::from("com.android.aconfig.storage.test_1"),
                String::from("enabled_rw"),
                StoredFlagType::ReadWriteBoolean,
                true,
            ),
            (
                String::from("com.android.aconfig.storage.test_2"),
                String::from("disabled_ro"),
                StoredFlagType::ReadOnlyBoolean,
                false,
            ),
            (
                String::from("com.android.aconfig.storage.test_2"),
                String::from("enabled_fixed_ro"),
                StoredFlagType::FixedReadOnlyBoolean,
                true,
            ),
            (
                String::from("com.android.aconfig.storage.test_2"),
                String::from("enabled_ro"),
                StoredFlagType::ReadOnlyBoolean,
                true,
            ),
            (
                String::from("com.android.aconfig.storage.test_4"),
                String::from("enabled_fixed_ro"),
                StoredFlagType::FixedReadOnlyBoolean,
                true,
            ),
            (
                String::from("com.android.aconfig.storage.test_4"),
                String::from("enabled_ro"),
                StoredFlagType::ReadOnlyBoolean,
                true,
            ),
        ];
        assert_eq!(flags, expected);
    }

    fn create_empty_temp_file() -> Result<NamedTempFile, AconfigStorageError> {
        let file = NamedTempFile::new().map_err(|_| {
            AconfigStorageError::FileCreationFail(anyhow!("Failed to create temp file"))
        })?;
        Ok(file)
    }

    #[test]
    // this test point locks down the flag info creation
    fn test_create_flag_info() {
        let package_table =
            write_bytes_to_temp_file(&create_test_package_table().into_bytes()).unwrap();
        let flag_table = write_bytes_to_temp_file(&create_test_flag_table().into_bytes()).unwrap();
        let flag_info = create_empty_temp_file().unwrap();

        let package_table_path = package_table.path().display().to_string();
        let flag_table_path = flag_table.path().display().to_string();
        let flag_info_path = flag_info.path().display().to_string();

        assert!(create_flag_info(&package_table_path, &flag_table_path, &flag_info_path).is_ok());

        let flag_info =
            FlagInfoList::from_bytes(&read_file_to_bytes(&flag_info_path).unwrap()).unwrap();
        let expected_flag_info = create_test_flag_info_list();
        assert_eq!(flag_info, expected_flag_info);
    }
}
