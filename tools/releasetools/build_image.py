#!/usr/bin/env python
#
# Copyright (C) 2011 The Android Open Source Project
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

"""
Builds output_image from the given input_directory, properties_file,
and writes the image to target_output_directory.

Usage:  build_image.py input_directory properties_file output_image \\
            target_output_directory
"""

from __future__ import print_function

import os
import os.path
import re
import shlex
import shutil
import subprocess
import sys

import common
import sparse_img


OPTIONS = common.OPTIONS

FIXED_SALT = "aee087a5be3b982978c923f566a94613496b417f2af592639bc80d141e34dfe7"
BLOCK_SIZE = 4096


def RunCommand(cmd, verbose=None):
  """Echo and run the given command.

  Args:
    cmd: the command represented as a list of strings.
    verbose: show commands being executed.
  Returns:
    A tuple of the output and the exit code.
  """
  if verbose is None:
    verbose = OPTIONS.verbose
  if verbose:
    print("Running: " + " ".join(cmd))
  p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  output, _ = p.communicate()

  if verbose:
    print(output.rstrip())
  return (output, p.returncode)


def GetVerityFECSize(partition_size):
  cmd = ["fec", "-s", str(partition_size)]
  output, exit_code = RunCommand(cmd, False)
  if exit_code != 0:
    return False, 0
  return True, int(output)


def GetVerityTreeSize(partition_size):
  cmd = ["build_verity_tree", "-s", str(partition_size)]
  output, exit_code = RunCommand(cmd, False)
  if exit_code != 0:
    return False, 0
  return True, int(output)


def GetVerityMetadataSize(partition_size):
  cmd = ["system/extras/verity/build_verity_metadata.py", "size",
         str(partition_size)]
  output, exit_code = RunCommand(cmd, False)
  if exit_code != 0:
    return False, 0
  return True, int(output)


def GetVeritySize(partition_size, fec_supported):
  success, verity_tree_size = GetVerityTreeSize(partition_size)
  if not success:
    return 0
  success, verity_metadata_size = GetVerityMetadataSize(partition_size)
  if not success:
    return 0
  verity_size = verity_tree_size + verity_metadata_size
  if fec_supported:
    success, fec_size = GetVerityFECSize(partition_size + verity_size)
    if not success:
      return 0
    return verity_size + fec_size
  return verity_size


def GetSimgSize(image_file):
  simg = sparse_img.SparseImage(image_file, build_map=False)
  return simg.blocksize * simg.total_blocks


def ZeroPadSimg(image_file, pad_size):
  blocks = pad_size // BLOCK_SIZE
  print("Padding %d blocks (%d bytes)" % (blocks, pad_size))
  simg = sparse_img.SparseImage(image_file, mode="r+b", build_map=False)
  simg.AppendFillChunk(0, blocks)


def AVBCalcMaxImageSize(avbtool, footer_type, partition_size, additional_args):
  """Calculates max image size for a given partition size.

  Args:
    avbtool: String with path to avbtool.
    footer_type: 'hash' or 'hashtree' for generating footer.
    partition_size: The size of the partition in question.
    additional_args: Additional arguments to pass to 'avbtool
      add_hashtree_image'.
  Returns:
    The maximum image size or 0 if an error occurred.
  """
<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
  cmd = [avbtool, "add_%s_footer" % footer_type,
         "--partition_size", partition_size, "--calc_max_image_size"]
  cmd.extend(shlex.split(additional_args))

  (output, exit_code) = RunCommand(cmd)
  if exit_code != 0:
    return 0
  else:
    return int(output)
=======
  cmd = ["find", path, "-print"]
  output = common.RunAndCheckOutput(cmd, verbose=False)
  # increase by > 6% as number of files and directories is not whole picture.
  inodes = output.count('\n')
  spare_inodes = inodes * 6 // 100
  min_spare_inodes = 12
  if spare_inodes < min_spare_inodes:
    spare_inodes = min_spare_inodes
  return inodes + spare_inodes
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)


<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
def AVBAddFooter(image_path, avbtool, footer_type, partition_size,
                 partition_name, key_path, algorithm, salt,
                 additional_args):
  """Adds dm-verity hashtree and AVB metadata to an image.
=======
def GetFilesystemCharacteristics(fs_type, image_path, sparse_image=True):
  """Returns various filesystem characteristics of "image_path".
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)

  Args:
    image_path: Path to image to modify.
    avbtool: String with path to avbtool.
    footer_type: 'hash' or 'hashtree' for generating footer.
    partition_size: The size of the partition in question.
    partition_name: The name of the partition - will be embedded in metadata.
    key_path: Path to key to use or None.
    algorithm: Name of algorithm to use or None.
    salt: The salt to use (a hexadecimal string) or None.
    additional_args: Additional arguments to pass to 'avbtool
        add_hashtree_image'.

  Returns:
    True if the operation succeeded.
  """
  cmd = [avbtool, "add_%s_footer" % footer_type,
         "--partition_size", partition_size,
         "--partition_name", partition_name,
         "--image", image_path]

<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
  if key_path and algorithm:
    cmd.extend(["--key", key_path, "--algorithm", algorithm])
  if salt:
    cmd.extend(["--salt", salt])

  cmd.extend(shlex.split(additional_args))

  (_, exit_code) = RunCommand(cmd)
  return exit_code == 0


def AdjustPartitionSizeForVerity(partition_size, fec_supported):
  """Modifies the provided partition size to account for the verity metadata.

  This information is used to size the created image appropriately.

  Args:
    partition_size: the size of the partition to be verified.

  Returns:
    A tuple of the size of the partition adjusted for verity metadata, and
    the size of verity metadata.
  """
  key = "%d %d" % (partition_size, fec_supported)
  if key in AdjustPartitionSizeForVerity.results:
    return AdjustPartitionSizeForVerity.results[key]

  hi = partition_size
  if hi % BLOCK_SIZE != 0:
    hi = (hi // BLOCK_SIZE) * BLOCK_SIZE

  # verity tree and fec sizes depend on the partition size, which
  # means this estimate is always going to be unnecessarily small
  verity_size = GetVeritySize(hi, fec_supported)
  lo = partition_size - verity_size
  result = lo

  # do a binary search for the optimal size
  while lo < hi:
    i = ((lo + hi) // (2 * BLOCK_SIZE)) * BLOCK_SIZE
    v = GetVeritySize(i, fec_supported)
    if i + v <= partition_size:
      if result < i:
        result = i
        verity_size = v
      lo = i + BLOCK_SIZE
    else:
      hi = i

  if OPTIONS.verbose:
    print("Adjusted partition size for verity, partition_size: {},"
          " verity_size: {}".format(result, verity_size))
  AdjustPartitionSizeForVerity.results[key] = (result, verity_size)
  return (result, verity_size)


AdjustPartitionSizeForVerity.results = {}


def BuildVerityFEC(sparse_image_path, verity_path, verity_fec_path,
                   padding_size):
  cmd = ["fec", "-e", "-p", str(padding_size), sparse_image_path,
         verity_path, verity_fec_path]
  output, exit_code = RunCommand(cmd)
  if exit_code != 0:
    print("Could not build FEC data! Error: %s" % output)
    return False
  return True


def BuildVerityTree(sparse_image_path, verity_image_path, prop_dict):
  cmd = ["build_verity_tree", "-A", FIXED_SALT, sparse_image_path,
         verity_image_path]
  output, exit_code = RunCommand(cmd)
  if exit_code != 0:
    print("Could not build verity tree! Error: %s" % output)
    return False
  root, salt = output.split()
  prop_dict["verity_root_hash"] = root
  prop_dict["verity_salt"] = salt
  return True


def BuildVerityMetadata(image_size, verity_metadata_path, root_hash, salt,
                        block_device, signer_path, key, signer_args,
                        verity_disable):
  cmd = ["system/extras/verity/build_verity_metadata.py", "build",
         str(image_size), verity_metadata_path, root_hash, salt, block_device,
         signer_path, key]
  if signer_args:
    cmd.append("--signer_args=\"%s\"" % (' '.join(signer_args),))
  if verity_disable:
    cmd.append("--verity_disable")
  output, exit_code = RunCommand(cmd)
  if exit_code != 0:
    print("Could not build verity metadata! Error: %s" % output)
    return False
  return True


def Append2Simg(sparse_image_path, unsparse_image_path, error_message):
  """Appends the unsparse image to the given sparse image.

  Args:
    sparse_image_path: the path to the (sparse) image
    unsparse_image_path: the path to the (unsparse) image
  Returns:
    True on success, False on failure.
  """
  cmd = ["append2simg", sparse_image_path, unsparse_image_path]
  output, exit_code = RunCommand(cmd)
  if exit_code != 0:
    print("%s: %s" % (error_message, output))
    return False
  return True


def Append(target, file_to_append, error_message):
  """Appends file_to_append to target."""
=======
  if fs_type.startswith("ext"):
    cmd = ["tune2fs", "-l", unsparse_image_path]
  elif fs_type.startswith("f2fs"):
    cmd = ["fsck.f2fs", "-l", unsparse_image_path]

>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)
  try:
    with open(target, "a") as out_file, open(file_to_append, "r") as input_file:
      for line in input_file:
        out_file.write(line)
  except IOError:
    print(error_message)
    return False
  return True


def BuildVerifiedImage(data_image_path, verity_image_path,
                       verity_metadata_path, verity_fec_path,
                       padding_size, fec_supported):
  if not Append(verity_image_path, verity_metadata_path,
                "Could not append verity metadata!"):
    return False

  if fec_supported:
    # build FEC for the entire partition, including metadata
    if not BuildVerityFEC(data_image_path, verity_image_path,
                          verity_fec_path, padding_size):
      return False

    if not Append(verity_image_path, verity_fec_path, "Could not append FEC!"):
      return False

  if not Append2Simg(data_image_path, verity_image_path,
                     "Could not append verity data!"):
    return False
  return True


def UnsparseImage(sparse_image_path, replace=True):
  img_dir = os.path.dirname(sparse_image_path)
  unsparse_image_path = "unsparse_" + os.path.basename(sparse_image_path)
  unsparse_image_path = os.path.join(img_dir, unsparse_image_path)
  if os.path.exists(unsparse_image_path):
    if replace:
      os.unlink(unsparse_image_path)
    else:
      return True, unsparse_image_path
  inflate_command = ["simg2img", sparse_image_path, unsparse_image_path]
  (inflate_output, exit_code) = RunCommand(inflate_command)
  if exit_code != 0:
    print("Error: '%s' failed with exit code %d:\n%s" % (
        inflate_command, exit_code, inflate_output))
    os.remove(unsparse_image_path)
    return False, None
  return True, unsparse_image_path


def MakeVerityEnabledImage(out_file, fec_supported, prop_dict):
  """Creates an image that is verifiable using dm-verity.

  Args:
    out_file: the location to write the verifiable image at
    prop_dict: a dictionary of properties required for image creation and
               verification
  Returns:
    True on success, False otherwise.
  """
  # get properties
  image_size = int(prop_dict["partition_size"])
  block_dev = prop_dict["verity_block_device"]
  signer_key = prop_dict["verity_key"] + ".pk8"
  if OPTIONS.verity_signer_path is not None:
    signer_path = OPTIONS.verity_signer_path
  else:
    signer_path = prop_dict["verity_signer_cmd"]
  signer_args = OPTIONS.verity_signer_args

  # make a tempdir
  tempdir_name = common.MakeTempDir(suffix="_verity_images")

  # get partial image paths
  verity_image_path = os.path.join(tempdir_name, "verity.img")
  verity_metadata_path = os.path.join(tempdir_name, "verity_metadata.img")
  verity_fec_path = os.path.join(tempdir_name, "verity_fec.img")

  # build the verity tree and get the root hash and salt
  if not BuildVerityTree(out_file, verity_image_path, prop_dict):
    return False

  # build the metadata blocks
  root_hash = prop_dict["verity_root_hash"]
  salt = prop_dict["verity_salt"]
  verity_disable = "verity_disable" in prop_dict
  if not BuildVerityMetadata(image_size, verity_metadata_path, root_hash, salt,
                             block_dev, signer_path, signer_key, signer_args,
                             verity_disable):
    return False

  # build the full verified image
  target_size = int(prop_dict["original_partition_size"])
  verity_size = int(prop_dict["verity_size"])

  padding_size = target_size - image_size - verity_size
  assert padding_size >= 0

  if not BuildVerifiedImage(out_file,
                            verity_image_path,
                            verity_metadata_path,
                            verity_fec_path,
                            padding_size,
                            fec_supported):
    return False

  return True


def ConvertBlockMapToBaseFs(block_map_file):
  base_fs_file = common.MakeTempFile(prefix="script_gen_", suffix=".base_fs")
  convert_command = ["blk_alloc_to_base_fs", block_map_file, base_fs_file]
  (_, exit_code) = RunCommand(convert_command)
  return base_fs_file if exit_code == 0 else None


def CheckHeadroom(ext4fs_output, prop_dict):
  """Checks if there's enough headroom space available.

  Headroom is the reserved space on system image (via PRODUCT_SYSTEM_HEADROOM),
  which is useful for devices with low disk space that have system image
  variation between builds. The 'partition_headroom' in prop_dict is the size
  in bytes, while the numbers in 'ext4fs_output' are for 4K-blocks.

  Args:
    ext4fs_output: The output string from mke2fs command.
    prop_dict: The property dict.

  Returns:
    The check result.

  Raises:
    AssertionError: On invalid input.
  """
  assert ext4fs_output is not None
  assert prop_dict.get('fs_type', '').startswith('ext4')
  assert 'partition_headroom' in prop_dict
  assert 'mount_point' in prop_dict

  ext4fs_stats = re.compile(
      r'Created filesystem with .* (?P<used_blocks>[0-9]+)/'
      r'(?P<total_blocks>[0-9]+) blocks')
  last_line = ext4fs_output.strip().split('\n')[-1]
  m = ext4fs_stats.match(last_line)
  used_blocks = int(m.groupdict().get('used_blocks'))
  total_blocks = int(m.groupdict().get('total_blocks'))
  headroom_blocks = int(prop_dict['partition_headroom']) / BLOCK_SIZE
  adjusted_blocks = total_blocks - headroom_blocks
  if used_blocks > adjusted_blocks:
    mount_point = prop_dict["mount_point"]
    print("Error: Not enough room on %s (total: %d blocks, used: %d blocks, "
          "headroom: %d blocks, available: %d blocks)" % (
              mount_point, total_blocks, used_blocks, headroom_blocks,
              adjusted_blocks))
    return False
  return True

def CalculateSizeAndReserved(prop_dict, size):
  fs_type = prop_dict.get("fs_type", "")
  partition_headroom = int(prop_dict.get("partition_headroom", 0))
  # If not specified, give us 16MB margin for GetDiskUsage error ...
  reserved_size = int(prop_dict.get("partition_reserved_size", BYTES_IN_MB * 16))

  if fs_type == "erofs":
    reserved_size = int(prop_dict.get("partition_reserved_size", 0))
    if reserved_size == 0:
      # give .3% margin or a minimum size for AVB footer
      return max(size * 1003 // 1000, 256 * 1024)

  if fs_type.startswith("ext4") and partition_headroom > reserved_size:
    reserved_size = partition_headroom

  return size + reserved_size

def BuildImage(in_dir, prop_dict, out_file, target_out=None):
  """Build an image to out_file from in_dir with property prop_dict.

  Args:
    in_dir: path of input directory.
    prop_dict: property dictionary.
    out_file: path of the output image file.
    target_out: path of the product out directory to read device specific FS
        config files.

  Returns:
    True iff the image is built successfully.
  """
  # system_root_image=true: build a system.img that combines the contents of
  # /system and the ramdisk, and can be mounted at the root of the file system.
  origin_in = in_dir
  fs_config = prop_dict.get("fs_config")
  if (prop_dict.get("system_root_image") == "true" and
      prop_dict["mount_point"] == "system"):
    in_dir = common.MakeTempDir()
    # Change the mount point to "/".
    prop_dict["mount_point"] = "/"
    if fs_config:
      # We need to merge the fs_config files of system and ramdisk.
      merged_fs_config = common.MakeTempFile(prefix="root_fs_config",
                                             suffix=".txt")
      with open(merged_fs_config, "w") as fw:
        if "ramdisk_fs_config" in prop_dict:
          with open(prop_dict["ramdisk_fs_config"]) as fr:
            fw.writelines(fr.readlines())
        with open(fs_config) as fr:
          fw.writelines(fr.readlines())
      fs_config = merged_fs_config

  build_command = []
  fs_type = prop_dict.get("fs_type", "")
  run_e2fsck = False

  fs_spans_partition = True
  if fs_type.startswith("squash"):
    fs_spans_partition = False

  is_verity_partition = "verity_block_device" in prop_dict
  verity_supported = prop_dict.get("verity") == "true"
  verity_fec_supported = prop_dict.get("verity_fec") == "true"

  # Adjust the partition size to make room for the hashes if this is to be
  # verified.
  if verity_supported and is_verity_partition:
    partition_size = int(prop_dict.get("partition_size"))
    (adjusted_size, verity_size) = AdjustPartitionSizeForVerity(
        partition_size, verity_fec_supported)
    if not adjusted_size:
      return False
    prop_dict["partition_size"] = str(adjusted_size)
    prop_dict["original_partition_size"] = str(partition_size)
    prop_dict["verity_size"] = str(verity_size)

  # Adjust partition size for AVB hash footer or AVB hashtree footer.
  avb_footer_type = ''
  if prop_dict.get("avb_hash_enable") == "true":
    avb_footer_type = 'hash'
  elif prop_dict.get("avb_hashtree_enable") == "true":
    avb_footer_type = 'hashtree'

  if avb_footer_type:
    avbtool = prop_dict["avb_avbtool"]
    partition_size = prop_dict["partition_size"]
    # avb_add_hash_footer_args or avb_add_hashtree_footer_args.
    additional_args = prop_dict["avb_add_" + avb_footer_type + "_footer_args"]
    max_image_size = AVBCalcMaxImageSize(avbtool, avb_footer_type,
                                         partition_size, additional_args)
    if max_image_size == 0:
      return False
    prop_dict["partition_size"] = str(max_image_size)
    prop_dict["original_partition_size"] = partition_size

  disable_sparse = "disable_sparse" in prop_dict

  if fs_type.startswith("ext"):
    build_command = [prop_dict["ext_mkuserimg"]]
    if "extfs_sparse_flag" in prop_dict and not disable_sparse:
      build_command.append(prop_dict["extfs_sparse_flag"])
      run_e2fsck = True
    build_command.extend([in_dir, out_file, fs_type,
                          prop_dict["mount_point"]])
    build_command.append(prop_dict["partition_size"])
    if "journal_size" in prop_dict:
      build_command.extend(["-j", prop_dict["journal_size"]])
    if "timestamp" in prop_dict:
      build_command.extend(["-T", str(prop_dict["timestamp"])])
    if fs_config:
      build_command.extend(["-C", fs_config])
    if target_out:
      build_command.extend(["-D", target_out])
    if "block_list" in prop_dict:
      build_command.extend(["-B", prop_dict["block_list"]])
    if "base_fs_file" in prop_dict:
      base_fs_file = ConvertBlockMapToBaseFs(prop_dict["base_fs_file"])
      if base_fs_file is None:
        return False
      build_command.extend(["-d", base_fs_file])
    build_command.extend(["-L", prop_dict["mount_point"]])
    if "extfs_inode_count" in prop_dict:
      build_command.extend(["-i", prop_dict["extfs_inode_count"]])
    if "extfs_rsv_pct" in prop_dict:
      build_command.extend(["-M", prop_dict["extfs_rsv_pct"]])
    if "flash_erase_block_size" in prop_dict:
      build_command.extend(["-e", prop_dict["flash_erase_block_size"]])
    if "flash_logical_block_size" in prop_dict:
      build_command.extend(["-o", prop_dict["flash_logical_block_size"]])
    # Specify UUID and hash_seed if using mke2fs.
<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
    if prop_dict["ext_mkuserimg"] == "mkuserimg_mke2fs.sh":
=======
    if os.path.basename(prop_dict["ext_mkuserimg"]) == "mkuserimg_mke2fs":
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)
      if "uuid" in prop_dict:
        build_command.extend(["-U", prop_dict["uuid"]])
      if "hash_seed" in prop_dict:
        build_command.extend(["-S", prop_dict["hash_seed"]])
    if "ext4_share_dup_blocks" in prop_dict:
      build_command.append("-c")
    if "selinux_fc" in prop_dict:
      build_command.append(prop_dict["selinux_fc"])
<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
=======
  elif fs_type.startswith("erofs"):
    build_command = ["mkerofsimage.sh"]
    build_command.extend([in_dir, out_file])
    if "erofs_sparse_flag" in prop_dict and not disable_sparse:
      build_command.extend([prop_dict["erofs_sparse_flag"]])
    build_command.extend(["-m", prop_dict["mount_point"]])
    if target_out:
      build_command.extend(["-d", target_out])
    if fs_config:
      build_command.extend(["-C", fs_config])
    if "selinux_fc" in prop_dict:
      build_command.extend(["-c", prop_dict["selinux_fc"]])
    compressor = None
    if "erofs_default_compressor" in prop_dict:
      compressor = prop_dict["erofs_default_compressor"]
    if "erofs_compressor" in prop_dict:
      compressor = prop_dict["erofs_compressor"]
    if compressor:
      build_command.extend(["-z", compressor])
    if "timestamp" in prop_dict:
      build_command.extend(["-T", str(prop_dict["timestamp"])])
    if "uuid" in prop_dict:
      build_command.extend(["-U", prop_dict["uuid"]])
    if "block_list" in prop_dict:
      build_command.extend(["-B", prop_dict["block_list"]])
    if "erofs_pcluster_size" in prop_dict:
      build_command.extend(["-P", prop_dict["erofs_pcluster_size"]])
    if "erofs_share_dup_blocks" in prop_dict:
      build_command.extend(["-k", "4096"])
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)
  elif fs_type.startswith("squash"):
    build_command = ["mksquashfsimage.sh"]
    build_command.extend([in_dir, out_file])
    if "squashfs_sparse_flag" in prop_dict and not disable_sparse:
      build_command.extend([prop_dict["squashfs_sparse_flag"]])
    build_command.extend(["-m", prop_dict["mount_point"]])
    if target_out:
      build_command.extend(["-d", target_out])
    if fs_config:
      build_command.extend(["-C", fs_config])
    if "selinux_fc" in prop_dict:
      build_command.extend(["-c", prop_dict["selinux_fc"]])
    if "block_list" in prop_dict:
      build_command.extend(["-B", prop_dict["block_list"]])
    if "squashfs_block_size" in prop_dict:
      build_command.extend(["-b", prop_dict["squashfs_block_size"]])
    if "squashfs_compressor" in prop_dict:
      build_command.extend(["-z", prop_dict["squashfs_compressor"]])
    if "squashfs_compressor_opt" in prop_dict:
      build_command.extend(["-zo", prop_dict["squashfs_compressor_opt"]])
    if prop_dict.get("squashfs_disable_4k_align") == "true":
      build_command.extend(["-a"])
  elif fs_type.startswith("f2fs"):
    build_command = ["mkf2fsuserimg.sh"]
<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
    build_command.extend([out_file, prop_dict["partition_size"]])
=======
    build_command.extend([out_file, prop_dict["image_size"]])
    if "f2fs_sparse_flag" in prop_dict and not disable_sparse:
      build_command.extend([prop_dict["f2fs_sparse_flag"]])
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)
    if fs_config:
      build_command.extend(["-C", fs_config])
    build_command.extend(["-f", in_dir])
    if target_out:
      build_command.extend(["-D", target_out])
    if "selinux_fc" in prop_dict:
      build_command.extend(["-s", prop_dict["selinux_fc"]])
    build_command.extend(["-t", prop_dict["mount_point"]])
    if "timestamp" in prop_dict:
      build_command.extend(["-T", str(prop_dict["timestamp"])])
    if "block_list" in prop_dict:
      build_command.extend(["-B", prop_dict["block_list"]])
    build_command.extend(["-L", prop_dict["mount_point"]])
<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
=======
    if (needs_projid):
      build_command.append("--prjquota")
    if (needs_casefold):
      build_command.append("--casefold")
    if (needs_compress or prop_dict.get("f2fs_compress") == "true"):
      build_command.append("--compression")
    if (prop_dict.get("mount_point") != "data"):
      build_command.append("--readonly")
    if (prop_dict.get("f2fs_compress") == "true"):
      build_command.append("--sldc")
      if (prop_dict.get("f2fs_sldc_flags") == None):
        build_command.append(str(0))
      else:
        sldc_flags_str = prop_dict.get("f2fs_sldc_flags")
        sldc_flags = sldc_flags_str.split()
        build_command.append(str(len(sldc_flags)))
        build_command.extend(sldc_flags)
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)
  else:
    print("Error: unknown filesystem type '%s'" % (fs_type))
    return False

<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
  if in_dir != origin_in:
    # Construct a staging directory of the root file system.
    ramdisk_dir = prop_dict.get("ramdisk_dir")
    if ramdisk_dir:
      shutil.rmtree(in_dir)
      shutil.copytree(ramdisk_dir, in_dir, symlinks=True)
    staging_system = os.path.join(in_dir, "system")
    shutil.rmtree(staging_system, ignore_errors=True)
    shutil.copytree(origin_in, staging_system, symlinks=True)
=======
  try:
    mkfs_output = common.RunAndCheckOutput(build_command)
  except:
    try:
      du = GetDiskUsage(in_dir)
      du_str = "{} bytes ({} MB)".format(du, du // BYTES_IN_MB)
    # Suppress any errors from GetDiskUsage() to avoid hiding the real errors
    # from common.RunAndCheckOutput().
    except Exception:  # pylint: disable=broad-except
      logger.exception("Failed to compute disk usage with du")
      du_str = "unknown"
    print(
        "Out of space? Out of inodes? The tree size of {} is {}, "
        "with reserved space of {} bytes ({} MB).".format(
            in_dir, du_str,
            int(prop_dict.get("partition_reserved_size", 0)),
            int(prop_dict.get("partition_reserved_size", 0)) // BYTES_IN_MB))
    if ("image_size" in prop_dict and "partition_size" in prop_dict):
      print(
          "The max image size for filesystem files is {} bytes ({} MB), "
          "out of a total partition size of {} bytes ({} MB).".format(
              int(prop_dict["image_size"]),
              int(prop_dict["image_size"]) // BYTES_IN_MB,
              int(prop_dict["partition_size"]),
              int(prop_dict["partition_size"]) // BYTES_IN_MB))
    raise
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)

<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
  (mkfs_output, exit_code) = RunCommand(build_command)
  if exit_code != 0:
    print("Error: '%s' failed with exit code %d:\n%s" % (
        build_command, exit_code, mkfs_output))
    return False
=======
  if run_e2fsck and prop_dict.get("skip_fsck") != "true":
    unsparse_image = UnsparseImage(out_file, replace=False)

    # Run e2fsck on the inflated image file
    e2fsck_command = ["e2fsck", "-f", "-n", unsparse_image]
    try:
      common.RunAndCheckOutput(e2fsck_command)
    finally:
      os.remove(unsparse_image)

  return mkfs_output


def BuildImage(in_dir, prop_dict, out_file, target_out=None):
  """Builds an image for the files under in_dir and writes it to out_file.

  Args:
    in_dir: Path to input directory.
    prop_dict: A property dict that contains info like partition size. Values
        will be updated with computed values.
    out_file: The output image file.
    target_out: Path to the TARGET_OUT directory as in Makefile. It actually
        points to the /system directory under PRODUCT_OUT. fs_config (the one
        under system/core/libcutils) reads device specific FS config files from
        there.

  Raises:
    BuildImageError: On build image failures.
  """
  in_dir, fs_config = SetUpInDirAndFsConfig(in_dir, prop_dict)

  build_command = []
  fs_type = prop_dict.get("fs_type", "")

  fs_spans_partition = True
  if fs_type.startswith("squash") or fs_type.startswith("erofs"):
    fs_spans_partition = False
  elif fs_type.startswith("f2fs") and prop_dict.get("f2fs_compress") == "true":
    fs_spans_partition = False

  # Get a builder for creating an image that's to be verified by Verified Boot,
  # or None if not applicable.
  verity_image_builder = verity_utils.CreateVerityImageBuilder(prop_dict)

  disable_sparse = "disable_sparse" in prop_dict
  mkfs_output = None
  if (prop_dict.get("use_dynamic_partition_size") == "true" and
      "partition_size" not in prop_dict):
    # If partition_size is not defined, use output of `du' + reserved_size.
    # For compressed file system, it's better to use the compressed size to avoid wasting space.
    if fs_type.startswith("erofs"):
      mkfs_output = BuildImageMkfs(in_dir, prop_dict, out_file, target_out, fs_config)
      if "erofs_sparse_flag" in prop_dict and not disable_sparse:
        image_path = UnsparseImage(out_file, replace=False)
        size = GetDiskUsage(image_path)
        os.remove(image_path)
      else:
        size = GetDiskUsage(out_file)
    else:
      size = GetDiskUsage(in_dir)
    logger.info(
        "The tree size of %s is %d MB.", in_dir, size // BYTES_IN_MB)
    size = CalculateSizeAndReserved(prop_dict, size)
    # Round this up to a multiple of 4K so that avbtool works
    size = common.RoundUpTo4K(size)
    if fs_type.startswith("ext"):
      prop_dict["partition_size"] = str(size)
      prop_dict["image_size"] = str(size)
      if "extfs_inode_count" not in prop_dict:
        prop_dict["extfs_inode_count"] = str(GetInodeUsage(in_dir))
      logger.info(
          "First Pass based on estimates of %d MB and %s inodes.",
          size // BYTES_IN_MB, prop_dict["extfs_inode_count"])
      BuildImageMkfs(in_dir, prop_dict, out_file, target_out, fs_config)
      sparse_image = False
      if "extfs_sparse_flag" in prop_dict and not disable_sparse:
        sparse_image = True
      fs_dict = GetFilesystemCharacteristics(fs_type, out_file, sparse_image)
      os.remove(out_file)
      block_size = int(fs_dict.get("Block size", "4096"))
      free_size = int(fs_dict.get("Free blocks", "0")) * block_size
      reserved_size = int(prop_dict.get("partition_reserved_size", 0))
      partition_headroom = int(fs_dict.get("partition_headroom", 0))
      if fs_type.startswith("ext4") and partition_headroom > reserved_size:
        reserved_size = partition_headroom
      if free_size <= reserved_size:
        logger.info(
            "Not worth reducing image %d <= %d.", free_size, reserved_size)
      else:
        size -= free_size
        size += reserved_size
        if reserved_size == 0:
          # add .3% margin
          size = size * 1003 // 1000
        # Use a minimum size, otherwise we will fail to calculate an AVB footer
        # or fail to construct an ext4 image.
        size = max(size, 256 * 1024)
        if block_size <= 4096:
          size = common.RoundUpTo4K(size)
        else:
          size = ((size + block_size - 1) // block_size) * block_size
      extfs_inode_count = prop_dict["extfs_inode_count"]
      inodes = int(fs_dict.get("Inode count", extfs_inode_count))
      inodes -= int(fs_dict.get("Free inodes", "0"))
      # add .2% margin or 1 inode, whichever is greater
      spare_inodes = inodes * 2 // 1000
      min_spare_inodes = 1
      if spare_inodes < min_spare_inodes:
        spare_inodes = min_spare_inodes
      inodes += spare_inodes
      prop_dict["extfs_inode_count"] = str(inodes)
      prop_dict["partition_size"] = str(size)
      logger.info(
          "Allocating %d Inodes for %s.", inodes, out_file)
    elif fs_type.startswith("f2fs") and prop_dict.get("f2fs_compress") == "true":
      prop_dict["partition_size"] = str(size)
      prop_dict["image_size"] = str(size)
      BuildImageMkfs(in_dir, prop_dict, out_file, target_out, fs_config)
      sparse_image = False
      if "f2fs_sparse_flag" in prop_dict and not disable_sparse:
        sparse_image = True
      fs_dict = GetFilesystemCharacteristics(fs_type, out_file, sparse_image)
      os.remove(out_file)
      block_count = int(fs_dict.get("block_count", "0"))
      log_blocksize = int(fs_dict.get("log_blocksize", "12"))
      size = block_count << log_blocksize
      prop_dict["partition_size"] = str(size)
    if verity_image_builder:
      size = verity_image_builder.CalculateDynamicPartitionSize(size)
    prop_dict["partition_size"] = str(size)
    logger.info(
        "Allocating %d MB for %s.", size // BYTES_IN_MB, out_file)

  prop_dict["image_size"] = prop_dict["partition_size"]

  # Adjust the image size to make room for the hashes if this is to be verified.
  if verity_image_builder:
    max_image_size = verity_image_builder.CalculateMaxImageSize()
    prop_dict["image_size"] = str(max_image_size)

  if not mkfs_output:
    mkfs_output = BuildImageMkfs(in_dir, prop_dict, out_file, target_out, fs_config)
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)

  # Check if there's enough headroom space available for ext4 image.
  if "partition_headroom" in prop_dict and fs_type.startswith("ext4"):
    if not CheckHeadroom(mkfs_output, prop_dict):
      return False

  if not fs_spans_partition:
    mount_point = prop_dict.get("mount_point")
    partition_size = int(prop_dict.get("partition_size"))
    image_size = GetSimgSize(out_file)
    if image_size > partition_size:
      print("Error: %s image size of %d is larger than partition size of "
            "%d" % (mount_point, image_size, partition_size))
      return False
    if verity_supported and is_verity_partition:
      ZeroPadSimg(out_file, partition_size - image_size)

  # Create the verified image if this is to be verified.
  if verity_supported and is_verity_partition:
    if not MakeVerityEnabledImage(out_file, verity_fec_supported, prop_dict):
      return False

  # Add AVB HASH or HASHTREE footer (metadata).
  if avb_footer_type:
    avbtool = prop_dict["avb_avbtool"]
    original_partition_size = prop_dict["original_partition_size"]
    partition_name = prop_dict["partition_name"]
    # key_path and algorithm are only available when chain partition is used.
    key_path = prop_dict.get("avb_key_path")
    algorithm = prop_dict.get("avb_algorithm")
    salt = prop_dict.get("avb_salt")
    # avb_add_hash_footer_args or avb_add_hashtree_footer_args
    additional_args = prop_dict["avb_add_" + avb_footer_type + "_footer_args"]
    if not AVBAddFooter(out_file, avbtool, avb_footer_type,
                        original_partition_size, partition_name, key_path,
                        algorithm, salt, additional_args):
      return False

  if run_e2fsck and prop_dict.get("skip_fsck") != "true":
    success, unsparse_image = UnsparseImage(out_file, replace=False)
    if not success:
      return False

    # Run e2fsck on the inflated image file
    e2fsck_command = ["e2fsck", "-f", "-n", unsparse_image]
    (e2fsck_output, exit_code) = RunCommand(e2fsck_command)

    os.remove(unsparse_image)

    if exit_code != 0:
      print("Error: '%s' failed with exit code %d:\n%s" % (
          e2fsck_command, exit_code, e2fsck_output))
      return False

  return True


def ImagePropFromGlobalDict(glob_dict, mount_point):
  """Build an image property dictionary from the global dictionary.

  Args:
    glob_dict: the global dictionary from the build system.
    mount_point: such as "system", "data" etc.
  """
  d = {}

  if "build.prop" in glob_dict:
    bp = glob_dict["build.prop"]
    if "ro.build.date.utc" in bp:
      d["timestamp"] = bp["ro.build.date.utc"]

  def copy_prop(src_p, dest_p):
    """Copy a property from the global dictionary.

    Args:
      src_p: The source property in the global dictionary.
      dest_p: The destination property.
    Returns:
      True if property was found and copied, False otherwise.
    """
    if src_p in glob_dict:
      d[dest_p] = str(glob_dict[src_p])
      return True
    return False

  common_props = (
      "extfs_sparse_flag",
<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
=======
      "erofs_default_compressor",
      "erofs_pcluster_size",
      "erofs_share_dup_blocks",
      "erofs_sparse_flag",
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)
      "squashfs_sparse_flag",
<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
      "selinux_fc",
=======
      "system_f2fs_compress",
      "system_f2fs_sldc_flags",
      "f2fs_sparse_flag",
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)
      "skip_fsck",
      "ext_mkuserimg",
      "verity",
      "verity_key",
      "verity_signer_cmd",
      "verity_fec",
      "verity_disable",
      "avb_enable",
      "avb_avbtool",
      "avb_salt",
  )
  for p in common_props:
    copy_prop(p, p)

  ro_mount_points = set([
      "odm",
      "odm_dlkm",
      "oem",
      "product",
      "system",
      "system_ext",
      "system_other",
      "vendor",
      "vendor_dlkm",
  ])

  # Tuple layout: (readonly, specific prop, general prop)
  fmt_props = (
      # Generic first, then specific file type.
      (False, "fs_type", "fs_type"),
      (False, "{}_fs_type", "fs_type"),

      # Ordering for these doesn't matter.
      (False, "{}_selinux_fc", "selinux_fc"),
      (False, "{}_size", "partition_size"),
      (True, "avb_{}_add_hashtree_footer_args", "avb_add_hashtree_footer_args"),
      (True, "avb_{}_algorithm", "avb_algorithm"),
      (True, "avb_{}_hashtree_enable", "avb_hashtree_enable"),
      (True, "avb_{}_key_path", "avb_key_path"),
      (True, "avb_{}_salt", "avb_salt"),
      (True, "ext4_share_dup_blocks", "ext4_share_dup_blocks"),
      (True, "{}_base_fs_file", "base_fs_file"),
      (True, "{}_disable_sparse", "disable_sparse"),
      (True, "{}_erofs_compressor", "erofs_compressor"),
      (True, "{}_erofs_pcluster_size", "erofs_pcluster_size"),
      (True, "{}_erofs_share_dup_blocks", "erofs_share_dup_blocks"),
      (True, "{}_extfs_inode_count", "extfs_inode_count"),
      (True, "{}_f2fs_compress", "f2fs_compress"),
      (True, "{}_f2fs_sldc_flags", "f2fs_sldc_flags"),
      (True, "{}_reserved_size", "partition_reserved_size"),
      (True, "{}_squashfs_block_size", "squashfs_block_size"),
      (True, "{}_squashfs_compressor", "squashfs_compressor"),
      (True, "{}_squashfs_compressor_opt", "squashfs_compressor_opt"),
      (True, "{}_squashfs_disable_4k_align", "squashfs_disable_4k_align"),
      (True, "{}_verity_block_device", "verity_block_device"),
  )

  # Translate prefixed properties into generic ones.
  if mount_point == "data":
    prefix = "userdata"
  else:
    prefix = mount_point

  for readonly, src_prop, dest_prop in fmt_props:
    if readonly and mount_point not in ro_mount_points:
      continue

    if src_prop == "fs_type":
      # This property is legacy and only used on a few partitions. b/202600377
      allowed_partitions = set(["system", "system_other", "data", "oem"])
      if mount_point not in allowed_partitions:
          continue

    if mount_point == "system_other":
      # Propagate system properties to system_other. They'll get overridden
      # after as needed.
      copy_prop(src_prop.format("system"), dest_prop)

    copy_prop(src_prop.format(prefix), dest_prop)

  # Set prefixed properties that need a default value.
  if mount_point in ro_mount_points:
    prop = "{}_journal_size".format(prefix)
    if not copy_prop(prop, "journal_size"):
      d["journal_size"] = "0"

    prop = "{}_extfs_rsv_pct".format(prefix)
    if not copy_prop(prop, "extfs_rsv_pct"):
      d["extfs_rsv_pct"] = "0"

  # Copy partition-specific properties.
  d["mount_point"] = mount_point
  if mount_point == "system":
<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
    copy_prop("avb_system_hashtree_enable", "avb_hashtree_enable")
    copy_prop("avb_system_add_hashtree_footer_args",
              "avb_add_hashtree_footer_args")
    copy_prop("avb_system_key_path", "avb_key_path")
    copy_prop("avb_system_algorithm", "avb_algorithm")
    copy_prop("fs_type", "fs_type")
    # Copy the generic system fs type first, override with specific one if
    # available.
    copy_prop("system_fs_type", "fs_type")
=======
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)
    copy_prop("system_headroom", "partition_headroom")
    copy_prop("system_root_image", "system_root_image")
<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
    copy_prop("ramdisk_dir", "ramdisk_dir")
    copy_prop("ramdisk_fs_config", "ramdisk_fs_config")
    copy_prop("ext4_share_dup_blocks", "ext4_share_dup_blocks")
    copy_prop("system_squashfs_compressor", "squashfs_compressor")
    copy_prop("system_squashfs_compressor_opt", "squashfs_compressor_opt")
    copy_prop("system_squashfs_block_size", "squashfs_block_size")
    copy_prop("system_squashfs_disable_4k_align", "squashfs_disable_4k_align")
    copy_prop("system_base_fs_file", "base_fs_file")
    copy_prop("system_extfs_inode_count", "extfs_inode_count")
    if not copy_prop("system_extfs_rsv_pct", "extfs_rsv_pct"):
      d["extfs_rsv_pct"] = "0"
  elif mount_point == "system_other":
    # We inherit the selinux policies of /system since we contain some of its
    # files.
    d["mount_point"] = "system"
    copy_prop("avb_system_hashtree_enable", "avb_hashtree_enable")
    copy_prop("avb_system_add_hashtree_footer_args",
              "avb_add_hashtree_footer_args")
    copy_prop("avb_system_key_path", "avb_key_path")
    copy_prop("avb_system_algorithm", "avb_algorithm")
    copy_prop("fs_type", "fs_type")
    copy_prop("system_fs_type", "fs_type")
    copy_prop("system_size", "partition_size")
    if not copy_prop("system_journal_size", "journal_size"):
      d["journal_size"] = "0"
    copy_prop("system_verity_block_device", "verity_block_device")
    copy_prop("system_squashfs_compressor", "squashfs_compressor")
    copy_prop("system_squashfs_compressor_opt", "squashfs_compressor_opt")
    copy_prop("system_squashfs_block_size", "squashfs_block_size")
    copy_prop("system_base_fs_file", "base_fs_file")
    copy_prop("system_extfs_inode_count", "extfs_inode_count")
    if not copy_prop("system_extfs_rsv_pct", "extfs_rsv_pct"):
      d["extfs_rsv_pct"] = "0"
=======
    copy_prop("root_dir", "root_dir")
    copy_prop("root_fs_config", "root_fs_config")
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)
  elif mount_point == "data":
    # Copy the generic fs type first, override with specific one if available.
    copy_prop("flash_logical_block_size", "flash_logical_block_size")
    copy_prop("flash_erase_block_size", "flash_erase_block_size")
<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
  elif mount_point == "cache":
    copy_prop("cache_fs_type", "fs_type")
    copy_prop("cache_size", "partition_size")
  elif mount_point == "vendor":
    copy_prop("avb_vendor_hashtree_enable", "avb_hashtree_enable")
    copy_prop("avb_vendor_add_hashtree_footer_args",
              "avb_add_hashtree_footer_args")
    copy_prop("avb_vendor_key_path", "avb_key_path")
    copy_prop("avb_vendor_algorithm", "avb_algorithm")
    copy_prop("vendor_fs_type", "fs_type")
    copy_prop("vendor_size", "partition_size")
    if not copy_prop("vendor_journal_size", "journal_size"):
      d["journal_size"] = "0"
    copy_prop("vendor_verity_block_device", "verity_block_device")
    copy_prop("ext4_share_dup_blocks", "ext4_share_dup_blocks")
    copy_prop("vendor_squashfs_compressor", "squashfs_compressor")
    copy_prop("vendor_squashfs_compressor_opt", "squashfs_compressor_opt")
    copy_prop("vendor_squashfs_block_size", "squashfs_block_size")
    copy_prop("vendor_squashfs_disable_4k_align", "squashfs_disable_4k_align")
    copy_prop("vendor_base_fs_file", "base_fs_file")
    copy_prop("vendor_extfs_inode_count", "extfs_inode_count")
    if not copy_prop("vendor_extfs_rsv_pct", "extfs_rsv_pct"):
      d["extfs_rsv_pct"] = "0"
  elif mount_point == "product":
    copy_prop("avb_product_hashtree_enable", "avb_hashtree_enable")
    copy_prop("avb_product_add_hashtree_footer_args",
              "avb_add_hashtree_footer_args")
    copy_prop("avb_product_key_path", "avb_key_path")
    copy_prop("avb_product_algorithm", "avb_algorithm")
    copy_prop("product_fs_type", "fs_type")
    copy_prop("product_size", "partition_size")
    if not copy_prop("product_journal_size", "journal_size"):
      d["journal_size"] = "0"
    copy_prop("product_verity_block_device", "verity_block_device")
    copy_prop("product_squashfs_compressor", "squashfs_compressor")
    copy_prop("product_squashfs_compressor_opt", "squashfs_compressor_opt")
    copy_prop("product_squashfs_block_size", "squashfs_block_size")
    copy_prop("product_squashfs_disable_4k_align", "squashfs_disable_4k_align")
    copy_prop("product_base_fs_file", "base_fs_file")
    copy_prop("product_extfs_inode_count", "extfs_inode_count")
    if not copy_prop("product_extfs_rsv_pct", "extfs_rsv_pct"):
      d["extfs_rsv_pct"] = "0"
  elif mount_point == "oem":
    copy_prop("fs_type", "fs_type")
    copy_prop("oem_size", "partition_size")
    if not copy_prop("oem_journal_size", "journal_size"):
      d["journal_size"] = "0"
    copy_prop("oem_extfs_inode_count", "extfs_inode_count")
    if not copy_prop("oem_extfs_rsv_pct", "extfs_rsv_pct"):
      d["extfs_rsv_pct"] = "0"
=======
    copy_prop("needs_casefold", "needs_casefold")
    copy_prop("needs_projid", "needs_projid")
    copy_prop("needs_compress", "needs_compress")
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)
  d["partition_name"] = mount_point
  return d


def LoadGlobalDict(filename):
  """Load "name=value" pairs from filename"""
  d = {}
  f = open(filename)
  for line in f:
    line = line.strip()
    if not line or line.startswith("#"):
      continue
    k, v = line.split("=", 1)
    d[k] = v
  f.close()
  return d


def main(argv):
  if len(argv) != 4:
    print(__doc__)
    sys.exit(1)

  in_dir = argv[0]
  glob_dict_file = argv[1]
  out_file = argv[2]
  target_out = argv[3]

  glob_dict = LoadGlobalDict(glob_dict_file)
  if "mount_point" in glob_dict:
    # The caller knows the mount point and provides a dictionay needed by
    # BuildImage().
    image_properties = glob_dict
  else:
    image_filename = os.path.basename(out_file)
    mount_point = ""
    if image_filename == "system.img":
      mount_point = "system"
    elif image_filename == "system_other.img":
      mount_point = "system_other"
    elif image_filename == "userdata.img":
      mount_point = "data"
    elif image_filename == "cache.img":
      mount_point = "cache"
    elif image_filename == "vendor.img":
      mount_point = "vendor"
    elif image_filename == "oem.img":
      mount_point = "oem"
    elif image_filename == "product.img":
      mount_point = "product"
    else:
      print("error: unknown image file name ", image_filename, file=sys.stderr)
      sys.exit(1)

    image_properties = ImagePropFromGlobalDict(glob_dict, mount_point)

  if not BuildImage(in_dir, image_properties, out_file, target_out):
    print("error: failed to build %s from %s" % (out_file, in_dir),
          file=sys.stderr)
    sys.exit(1)


if __name__ == '__main__':
  try:
    main(sys.argv[1:])
  finally:
    common.Cleanup()
