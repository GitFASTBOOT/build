<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
=======
#
# Copyright (C) 2019 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import common
import test_utils
from check_partition_sizes import CheckPartitionSizes

class CheckPartitionSizesTest(test_utils.ReleaseToolsTestCase):
  def setUp(self):
    self.info_dict = common.LoadDictionaryFromLines("""
        use_dynamic_partitions=true
        ab_update=true
        super_block_devices=super
        dynamic_partition_list=system vendor product
        super_partition_groups=group
        super_group_partition_list=system vendor product
        super_partition_size=202
        super_super_device_size=202
        super_group_group_size=100
        system_image_size=50
        vendor_image_size=20
        product_image_size=20
        system_other_image_size=10
        """.split("\n"))

  def test_ab(self):
    CheckPartitionSizes(self.info_dict)

  def test_non_ab(self):
    self.info_dict.update(common.LoadDictionaryFromLines("""
        ab_update=false
        super_partition_size=101
        super_super_device_size=101
        """.split("\n")))
    CheckPartitionSizes(self.info_dict)

  def test_non_dap(self):
    self.info_dict.update(common.LoadDictionaryFromLines("""
        use_dynamic_partitions=false
        """.split("\n")))
    with self.assertRaises(RuntimeError):
      CheckPartitionSizes(self.info_dict)

  def test_retrofit_dap(self):
    self.info_dict.update(common.LoadDictionaryFromLines("""
        dynamic_partition_retrofit=true
        super_block_devices=system vendor
        super_system_device_size=75
        super_vendor_device_size=25
        super_partition_size=100
        """.split("\n")))
    CheckPartitionSizes(self.info_dict)

  def test_ab_partition_too_big(self):
    self.info_dict.update(common.LoadDictionaryFromLines("""
        system_image_size=100
        """.split("\n")))
    with self.assertRaises(RuntimeError):
      CheckPartitionSizes(self.info_dict)

  def test_ab_group_too_big(self):
    self.info_dict.update(common.LoadDictionaryFromLines("""
        super_group_group_size=110
        """.split("\n")))
    with self.assertRaises(RuntimeError):
      CheckPartitionSizes(self.info_dict)

  def test_no_image(self):
    del self.info_dict["system_image_size"]
    with self.assertRaises(KeyError):
      CheckPartitionSizes(self.info_dict)

  def test_block_devices_not_match(self):
    self.info_dict.update(common.LoadDictionaryFromLines("""
        dynamic_partition_retrofit=true
        super_block_devices=system vendor
        super_system_device_size=80
        super_vendor_device_size=25
        super_partition_size=100
        """.split("\n")))
    with self.assertRaises(RuntimeError):
      CheckPartitionSizes(self.info_dict)

  def test_retrofit_vab(self):
    self.info_dict.update(common.LoadDictionaryFromLines("""
        virtual_ab=true
        virtual_ab_retrofit=true
        """.split("\n")))
    CheckPartitionSizes(self.info_dict)

  def test_retrofit_vab_too_big(self):
    self.info_dict.update(common.LoadDictionaryFromLines("""
        virtual_ab=true
        virtual_ab_retrofit=true
        system_image_size=100
        """.split("\n")))
    with self.assertRaises(RuntimeError):
      CheckPartitionSizes(self.info_dict)

  def test_vab(self):
    self.info_dict.update(common.LoadDictionaryFromLines("""
        virtual_ab=true
        super_partition_size=101
        super_super_device_size=101
        """.split("\n")))
    CheckPartitionSizes(self.info_dict)

  def test_vab_too_big(self):
    self.info_dict.update(common.LoadDictionaryFromLines("""
        virtual_ab=true
        super_partition_size=100
        super_super_device_size=100
        system_image_size=100
        """.split("\n")))
    with self.assertRaises(RuntimeError):
      CheckPartitionSizes(self.info_dict)

  def test_vab_too_big_with_system_other(self):
    self.info_dict.update(common.LoadDictionaryFromLines("""
        virtual_ab=true
        system_other_image_size=20
        super_partition_size=101
        super_super_device_size=101
        """.split("\n")))
    with self.assertRaises(RuntimeError):
      CheckPartitionSizes(self.info_dict)
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)
