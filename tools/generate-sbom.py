#!/usr/bin/env python3
#
# Copyright (C) 2023 The Android Open Source Project
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
Generate the SBOM of the current target product in SPDX format.
Usage example:
  generate-sbom.py --output_file out/target/product/vsoc_x86_64/sbom.spdx \
                   --metadata out/target/product/vsoc_x86_64/sbom-metadata.csv \
                   --product_out_dir=out/target/product/vsoc_x86_64 \
                   --build_version $(cat out/target/product/vsoc_x86_64/build_fingerprint.txt) \
                   --product_mfr=Google
"""

import argparse
import csv
import datetime
import google.protobuf.text_format as text_format
import hashlib
import json
import os
import project_metadata_pb2
import re

# Common
SPDXID = 'SPDXID'
CREATED = 'Created'
EXTERNAL_DOCUMENT_REF = 'ExternalDocumentRef'

# Package
PACKAGE_NAME = 'PackageName'
PACKAGE_DOWNLOAD_LOCATION = 'PackageDownloadLocation'
PACKAGE_VERSION = 'PackageVersion'
PACKAGE_SUPPLIER = 'PackageSupplier'
FILES_ANALYZED = 'FilesAnalyzed'
# Package license
PACKAGE_LICENSE_CONCLUDED = 'PackageLicenseConcluded'
PACKAGE_LICENSE_INFO_FROM_FILES = 'PackageLicenseInfoFromFiles'
PACKAGE_LICENSE_DECLARED = 'PackageLicenseDeclared'
PACKAGE_LICENSE_COMMENTS = 'PackageLicenseComments'

# File
FILE_NAME = 'FileName'
FILE_CHECKSUM = 'FileChecksum'
# File license
LICENSE_CONCLUDED = 'LicenseConcluded'
LICENSE_INFO_IN_FILE = 'LicenseInfoInFile'
LICENSE_COMMENTS = 'LicenseComments'
FILE_COPYRIGHT_TEXT = 'FileCopyrightText'
FILE_NOTICE = 'FileNotice'
FILE_ATTRIBUTION_TEXT = 'FileAttributionText'

# Relationship
REL_DESCRIBES = 'DESCRIBES'
REL_VARIANT_OF = 'VARIANT_OF'
REL_GENERATED_FROM = 'GENERATED_FROM'

# Package type
PKG_SOURCE = 'SOURCE'
PKG_UPSTREAM = 'UPSTREAM'
PKG_PREBUILT = 'PREBUILT'


def get_args():
  parser = argparse.ArgumentParser()
  parser.add_argument('-v', '--verbose', action='store_true', default=True, help='Print more information.')
  parser.add_argument('--output_file', required=True, help='The generated SBOM file in SPDX format.')
  parser.add_argument('--metadata', required=True, help='The SBOM metadata file path.')
  parser.add_argument('--product_out_dir', required=True, help='The parent directory of all the installed files.')
  parser.add_argument('--build_version', required=True, help='The build version.')
  parser.add_argument('--product_mfr', required=True, help='The product manufacturer.')

  return parser.parse_args()


def log(*info):
  if args.verbose:
    for i in info:
      print(i)


def new_package_record(id, name, version, supplier, files_analyzed='false', declared_license=None,
    license_comments=None):
  package = {
      PACKAGE_NAME: name,
      SPDXID: id,
      PACKAGE_DOWNLOAD_LOCATION: 'NONE',
      PACKAGE_VERSION: version,
      PACKAGE_SUPPLIER: supplier,
      FILES_ANALYZED: files_analyzed,
  }
  if declared_license:
    package[PACKAGE_LICENSE_DECLARED] = declared_license
  if license_comments:
    package[LICENSE_COMMENTS] = '<text>' + license_comments + '</text>'
  return package


def new_file_record(id, name, checksum):
  return {
      FILE_NAME: name,
      SPDXID: id,
      FILE_CHECKSUM: checksum
  }


def encode_for_spdxid(s):
  """Simple encode for string values used in SPDXID which uses the charset of A-Za-Z0-9./-"""
  result = ''
  for c in s:
    if c.isalnum() or c in './-':
      result += c
    elif c in '_@':
      result += '-'
    else:
      result += '0x' + c.encode('utf-8').hex()
  return result


def new_package_id(package_name, type):
  return 'SPDXRef-{}-{}'.format(type, encode_for_spdxid(package_name))


def new_file_id(file_path):
  return 'SPDXRef-' + encode_for_spdxid(file_path)


def new_relationship_record(id1, relationship, id2):
  return 'Relationship {} {} {}'.format(id1, relationship, id2)


def checksum(file_path):
  file_path = args.product_out_dir + '/' + file_path
  h = hashlib.sha1()
  if os.path.islink(file_path):
    h.update(os.readlink(file_path).encode('utf-8'))
  else:
    with open(file_path, "rb") as f:
      h.update(f.read())
  return "SHA1: " + h.hexdigest()


def get_sbom_fragments(module_path):
  external_doc_ref = None
  packages = []
  relationships = []

  metadata_path = module_path
  while not os.path.exists(metadata_path + '/METADATA') and metadata_path:
    metadata_path = os.path.dirname(metadata_path)

  metadata_name = None
  if metadata_path:
    log("[{}]: found METADATA file: {}".format(module_path, metadata_path + '/METADATA'))
    project_metadata = project_metadata_pb2.Metadata()
    with open(metadata_path + '/METADATA', "rt") as f:
      text_format.Parse(f.read(), project_metadata)
    metadata_name = project_metadata.name
  else:
    log("[{}]: cannot find METADATA file".format(module_path))

  if module_path.startswith('external/') and module_path.find('chromium-webview') == -1:
    # Source fork packges
    # TODO: if module_path != metadata_path and module_path uses different license, the name should be derived from module_path so its specific license can be reported
    name = metadata_name if metadata_name else os.path.basename(metadata_path if metadata_path else module_path)
    source_package_id = new_package_id(name, PKG_SOURCE)
    declared_license, license_comments = get_license_info(module_path)
    source_package = new_package_record(source_package_id, name, args.build_version, args.product_mfr,
                                        declared_license=declared_license,
                                        license_comments=license_comments)
    # TODO: check if upstream package SBOM link exists. The upstream package is created when there is NO upstream package SBOM link.
    upstream_package_id = new_package_id(name, PKG_UPSTREAM)
    upstream_package = new_package_record(upstream_package_id, name, args.build_version, args.product_mfr,
                                          declared_license=declared_license,
                                          license_comments=license_comments)
    packages += [source_package, upstream_package]
    relationships.append(new_relationship_record(source_package_id, REL_VARIANT_OF, upstream_package_id))
  elif module_path.startswith('prebuilts/') or module_path.find('chromium-webview') > -1:
    # TODO: upstream package SBOM link should always exists, and add relationship prebuilt_package_id VARIANT_OF upstream SBOM
    # Prebuilt fork packages
    name = module_path.removeprefix('prebuilts/').replace('/', '-')
    if metadata_name:
      name = metadata_name
    elif metadata_path and metadata_path != module_path:
      name = metadata_path.removeprefix('prebuilts/').replace('/', '-')

    prebuilt_package_id = new_package_id(name, PKG_PREBUILT)
    declared_license, license_comments = get_license_info(module_path)
    prebuilt_package = new_package_record(prebuilt_package_id, name, args.build_version, args.product_mfr,
                                          declared_license=declared_license,
                                          license_comments=license_comments)
    packages.append(prebuilt_package)

  return external_doc_ref, packages, relationships


def get_license_info(module_path):
  filepath = module_path + '/Android.bp'
  if not os.path.exists(filepath):
    return None, 'TODO'

  bp = parse_android_bp(filepath)
  if not bp.get('license'):
    return None, 'TODO'

  licenses = [l.removeprefix('SPDX-license-identifier-') for l in bp['license']['license_kinds']]
  declared_license = ' OR '.join(licenses)
  license_comments = json.dumps(bp['license'], indent=4)

  return declared_license, license_comments


bp_path_to_json = {}


def parse_android_bp(file_path):
  global bp_path_to_json
  if bp_path_to_json.get(file_path):
    return bp_path_to_json[file_path]

  log("Parsing " + file_path)
  with open(file_path, 'rt') as f:
    text = f.read()
    text = re.sub(r'^\s*//.*', '', text, flags=re.MULTILINE)  # remove // comments
    text = re.sub(r'^/\*(?:[^/*][^*]*[*]+)*/', '', text)  # remove /* */ comments
    text = re.sub(r',\s*//.*$', r',', text, flags=re.MULTILINE)  # remove trailing comments

    text = re.sub(r'^\s*(\w+)\s*{', r'\1: {', text, flags=re.MULTILINE)  # add colon after module type name
    text = re.sub(r'^(\s*)(\w+):', r'\1"\2":', text, flags=re.MULTILINE)  # double quote the module type name

    text = re.sub(r',(\s*)}', r'\1}', text, flags=re.MULTILINE)  # remove the comma after the last property of object
    text = re.sub(r',(\s*)]', r'\1]', text, flags=re.MULTILINE)  # remove the comma after the last element of array

    text = re.sub(r'"\s*\+\s*"', '', text)  # concat string values on multiple lines and joined with +

    text = re.sub(r'^\s*(\w+)\s*=(.*)]$', r'"\1":\2],', text, flags=re.MULTILINE)  # change build = [] to "build": [],
    text = re.sub(r'^\s*(\w+)\s*=(.*)\[$', r'"\1":\2[', text, flags=re.MULTILINE)  # change xxxx = [ to "xxxx": [
    text = re.sub(r'^\s*(\w+)\s*=\s*("?.*"?)$', r'"\1": \2,', text,
                  flags=re.MULTILINE)  # change dat_file = "icu*.dat" to "dat_file": "icu*.dat",

    text = re.sub(r'^}$', r'},', text, flags=re.MULTILINE)  # add comma after the } of each module
    text = re.sub(r'^]$', r'],', text, flags=re.MULTILINE)  # add comma after the ] of values like unbundled_visibility

    text = re.sub(r'\s*(\w+):\s*("[^\[\]{},]*")(,?)', r' "\1": \2\3 ', text,
                  flags=re.MULTILINE)  # double quote the property like suffix: "32"
    text = re.sub(r'(\s*"\w+"):\s*([^"\[\]{},]*)(,?)$', r'\1: "\2"\3', text,
                  flags=re.MULTILINE)  # double quote the value like "visibility": xxxx
    text = text.replace('+\n', '')

    text = re.sub(r']\s*\+\s*(\w+)(,?)$', r', "\1" ]\2', text, flags=re.MULTILINE)  # ] + xxxxx --> , "xxxx" ]
    text = re.sub(r'\s*(\w+)\s*\+\s*\[', r'[ "\1", ', text, flags=re.MULTILINE)  # xxxxx + [ --> [ "xxxx" ,
    text = re.sub(r'\s*]\s*\+\s*\[', r', ', text, flags=re.MULTILINE)  # ] + [ --> ,

    text = re.sub(r'"\s*\+\s*(\w+)\s*', r'\1" ', text, flags=re.MULTILINE)  # "xxxxxx" + yyy --> "xxxxxyyyy"
    text = re.sub(r'\s*(\w+)\s*\+\s*"(.+)"\s*', r'"\1\2" ', text,
                  flags=re.MULTILINE)  # xxxx + "yyyyyy" --> "xxxxyyyyyy"
    text = re.sub(r'\s*"(.+)"\s*\+\s*"(.+)"\s*', r' "\1\2" ', text,
                  flags=re.MULTILINE)  # "xxxx" + "yyyyyy" --> "xxxxyyyyyy"

    text = text.strip().removesuffix(',')  # remove the comma after the last module

    try:
      bp_json = json.loads('{' + text + '}')
      bp_path_to_json[file_path] = bp_json
      log("End parsing " + file_path)
      return bp_json
    except json.JSONDecodeError:
      log(text)
      raise


def write_record(f, record):
  if record.__class__.__name__ == 'dict':
    for k, v in record.items():
      if k == EXTERNAL_DOCUMENT_REF:
        for ref in v:
          f.write('{}: {}\n'.format(k, ref))
      else:
        f.write('{}: {}\n'.format(k, v))
  elif record.__class__.__name__ == 'str':
    f.write(record + '\n')
  f.write('\n')


def sort_rels(rel):
  # rel = 'Relationship file_id GENERATED_FROM package_id'
  fields = rel.split(' ')
  return fields[3] + fields[1]


def main():
  global args
  args = get_args()
  log("Args:", vars(args))

  doc_id = 'SPDXRef-DOCUMENT'
  doc_header = {
      'SPDXVersion': 'SPDX-2.3',
      'DataLicense': 'CC0-1.0',
      SPDXID: doc_id,
      'DocumentName': args.build_version,
      'DocumentNamespace': '<document namespace here>',
      'Creator': 'Google, LLC',
      'Created': '<timestamp>',
      EXTERNAL_DOCUMENT_REF: [],
  }

  product_package_id = 'SPDXRef-PRODUCT'
  product_package = new_package_record(product_package_id, 'PRODUCT', args.build_version, args.product_mfr,
                                       files_analyzed='true')

  platform_package_id = 'SPDXRef-PLATFORM'
  platform_package = new_package_record(platform_package_id, 'PLATFORM', args.build_version, args.product_mfr)

  # Scan the metadata in CSV file and create the corresponding package and file records in SPDX
  product_files = []
  package_ids = []
  package_records = []
  rels_file_gen_from = []
  with open(args.metadata, newline='') as metadata_file:
    reader = csv.DictReader(metadata_file)
    for row in reader:
      installed_file = row['installed_file']
      module_path = row['module_path']

      file_id = new_file_id(installed_file)
      product_files.append(new_file_record(file_id, installed_file, checksum(installed_file)))

      if module_path.startswith('external/') or module_path.startswith('prebuilts/'):
        # File from source fork packages and prebuilt fork packages
        external_doc_ref, pkgs, rels = get_sbom_fragments(module_path)
        if len(pkgs) > 0:
          if external_doc_ref:
            doc_header[EXTERNAL_DOCUMENT_REF].append(external_doc_ref)
          for p in pkgs:
            if not p[SPDXID] in package_ids:
              package_ids.append(p[SPDXID])
              package_records.append(p)
          for rel in rels:
            if not rel in package_records:
              package_records.append(rel)
          source_fork_package_id = pkgs[0][SPDXID]  # The first package should be the source fork package
          rels_file_gen_from.append(new_relationship_record(file_id, REL_GENERATED_FROM, source_fork_package_id))
      else:
        # File from platform package
        rels_file_gen_from.append(new_relationship_record(file_id, REL_GENERATED_FROM, platform_package_id))

  all_records = [
      doc_header,
      product_package,
      new_relationship_record(doc_id, REL_DESCRIBES, product_package_id),
  ]
  all_records += product_files
  all_records.append(platform_package)
  all_records += package_records
  rels_file_gen_from.sort(key=sort_rels)
  all_records += rels_file_gen_from

  # Output
  doc_header[CREATED] = datetime.datetime.now(tz=datetime.timezone.utc).isoformat()
  with open(args.output_file, 'w', encoding="utf-8") as output_file:
    for rec in all_records:
      write_record(output_file, rec)


if __name__ == '__main__':
  main()
