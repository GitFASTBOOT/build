#!/usr/bin/env python

import os,sys
import struct
from apkverify import ApkSignature

key_id_map = {
    1: "platform",
    2: "media",
    3: "shared",
    4: "testkey",
    5: "verity",
    6: "releasekey",
    7: "networkstack",
}

key_name_map = {
    "platform": 1,
    "media": 2,
    "shared": 3,
    "testkey": 4,
    "verity": 5,
    "releasekey": 6,
    "networkstack": 7,
}

def write_key_id(apk_path, key_name):
    key_id = key_name_map.get(key_name, -1)
    _,_,_,_,_,offset = ApkSignature(apk_path).v2_zipfindsig()
    # ApkSignature(sys.argv[1]).verify()
    f = open(apk_path,'rb+')
    f.seek(offset)
    # binary_format = bytearray(byte_arr)
    f.write(bytearray([key_id]))
    f.close()
    return

def get_key_name(apk_path):
    _,_,_,_,_,offset = ApkSignature(apk_path).v2_zipfindsig()
    if offset == -1:
        print("%s not has verify padding block", apk_path)
        return
    f = open(apk_path,'rb+')
    print("get_key_name %s ^^^^^^^^^^^^^^^ %s" % (apk_path, offset))
    f.seek(offset)
    key_id = f.read(1)
    print("%s" % struct.unpack("<B", key_id)[0])
    f.close()
    return key_id_map.get(struct.unpack("<B", key_id)[0], "UNKNOWN")

if __name__ == '__main__':
    """ Confirm input (very) briefly """
    if len(sys.argv) != 3 and len(sys.argv) != 2:
        print("Usage: %s apk_path key_name" % sys.argv[0])
        exit(2)
    if len(sys.argv) == 3:
        write_key_id(sys.argv[1], sys.argv[2])
    key_name = get_key_name(sys.argv[1])
    print("%s ^^^^^^^^^^^" % key_name)
    exit(0)
