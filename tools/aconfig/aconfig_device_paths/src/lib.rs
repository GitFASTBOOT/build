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

//! Library for finding all aconfig on-device protobuf file paths.

use anyhow::Result;
use std::path::PathBuf;

use std::fs;

fn read_partition_paths() -> Vec<PathBuf> {
    include_str!("../partition_aconfig_flags_paths.txt")
        .split(",")
        .map(|s| s.trim_start_matches('\n').trim_matches('"'))
        .filter(|s| !s.is_empty())
        .map(|s| PathBuf::from(s.to_string()))
        .collect()
}

/// Determine all paths that contain an aconfig protobuf file.
pub fn parsed_flags_proto_paths() -> Result<Vec<PathBuf>> {
    let mut result: Vec<PathBuf> = read_partition_paths();

    for dir in fs::read_dir("/apex")? {
        let dir = dir?;

        // Only scan the currently active version of each mainline module; skip the @version dirs.
        if dir.file_name().as_encoded_bytes().iter().any(|&b| b == b'@') {
            continue;
        }

        let mut path = PathBuf::from("/apex");
        path.push(dir.path());
        path.push("etc");
        path.push("aconfig_flags.pb");
        if path.exists() {
            result.push(path);
        }
    }

    Ok(result)
}

#[cfg(test)] // Conditional compilation for tests
mod tests {
    use super::*; // Import names from parent module

    #[test]
    fn test_read_partition_paths() {
        assert_eq!(read_partition_paths().len(), 4);
    }
}
