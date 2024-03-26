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
use std::fs;
use tempfile::NamedTempFile;

/// Create temp file copy
pub(crate) fn copy_to_temp_file(source_file: &str) -> Result<NamedTempFile> {
    let file = NamedTempFile::new()?;
    fs::copy(source_file, file.path())?;
    Ok(file)
}
