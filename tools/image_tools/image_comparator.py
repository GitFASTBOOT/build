#!/usr/bin/env python3
import os,sys,hashlib,re
import subprocess
import tempfile
import zipfile
from apkverify import is_apk_file

global_mismatch_result = []
oneimage_unique_items = []
twoimage_unique_items = []
'''default mount point for image '''
onedir = '/mnt/oneimage'
twodir = '/mnt/twoimage'

def sumfile(fobj):
    m = hashlib.md5()
    while True:
        d = fobj.read(8096)
        if not d:
            break
        m.update(d)
    return m.hexdigest()

def md5sum(fname):
    if fname == '-':
        ret = sumfile(sys.stdin)
    else:
        try:
            print("%s" % fname)
            #f = file(fname, 'rb')
            f = open(fname, 'rb')
        except:
            return 'Failed to open file'
        ret = sumfile(f)
        f.close()
    return ret

def walkdirs(dir1, dir2):
    dirsa = []
    dirsb = []

    for directory in os.walk(dir1):
        relativedirname = pathsep + re.sub(dir1, "", directory[0])
        if relativedirname != pathsep:
                dirsa.append(relativedirname)
    for directory in os.walk(dir2):
        relativedirname = pathsep + re.sub(dir2, "", directory[0])
        if relativedirname != pathsep:
                dirsb.append(relativedirname)
    # Return matches for further inspection.
    return set(dirsa).intersection(set(dirsb))

def complists(dir1, dir2):
    print("#######################################")
    print("Comparing \n%s \n%s" % (dir1, dir2))
    print("#######################################")
    dira = []
    dirb = []
    for file in os.listdir(dir1):
        dira.append(file)
    for file in os.listdir(dir2):
        dirb.append(file)
    indir1 = set(dira).difference(set(dirb))
    indir2 = set(dirb).difference(set(dira))
    return (indir1, indir2, set(dira).intersection(set(dirb)))

def comapkmd5(old_apk):
    fd,fn = tempfile.mkstemp('tmp','')
    os.close(fd)
    zin = zipfile.ZipFile (old_apk, 'r')
    zout = zipfile.ZipFile (fn, 'w')
    for item in zin.infolist():
        buffer = zin.read(item.filename)
        if (item.filename!= "META-INF/CERT.RSA"):
            zout.writestr(item, buffer)
    zout.close()
    zin.close()
    apkmd5 = md5sum(fn)
    os.remove(fn)
    return apkmd5

def comfiles(files, fdir, sdir):
    firstdir = {}
    secdir = {}
    # Create an absolute path to them from the relative filename and get the md5.
    for f in files:
        of = fdir + pathsep + f
        sf = sdir + pathsep + f
        if os.path.isdir(of) and os.path.isdir(sf):
            continue
        if os.path.islink(of) and os.path.islink(sf):
            continue
        lite_result_check, firstdir[f], lite_errors = is_apk_file(of, validate=True)
        if lite_result_check:
            firstdir[f] = comapkmd5(of)
            secdir[f] = comapkmd5(sf)
            # full_result_check, secdir[f], full_errors = is_apk_file(sf, validate=True)
        else:
            firstdir[f] = md5sum(of)
            secdir[f] = md5sum(sf)
    for x in firstdir:
        print("firstdir %s :::: %s:" % (x, firstdir[x]))
        print("secdir %s :::: %s:" % (x, secdir[x]))
        if firstdir[x] != secdir[x]:
            global_mismatch_result.append(fdir[len(onedir)+1:] + pathsep + x)
            print("File %s in both targets but does not match!" % x)
    print("\n")

def outp(datum, fdir, sdir):
    if len(datum[0]) > 0:
        print("Items in \"%s\" and not in \"%s\":" % (fdir, sdir))
        for z in datum[0]:
            oneimage_unique_items.append(fdir[len(onedir)+1:] + pathsep + z)
            print("   ", z)
        print("\n------------------------------")
    else:
        print("No unique items in \"%s\"" % (fdir))
    if len(datum[1]) > 0:
        print("Items in \"%s\" and not in \"%s\":" %(sdir, fdir))
        for z in datum[1]:
            twoimage_unique_items.append(sdir[len(twodir)+1:] + pathsep + z)
            print("   ", z)
        print("\n------------------------------")
    else:
        print("No unique items in \"%s\"" % (sdir))
    if len(datum[2]) > 0:
        comfiles(datum[2], fdir, sdir)

def execute(cmd):
    print(cmd)
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = map(lambda b: b.decode('utf-8'), p.communicate())
    return p.returncode == 0, out, err

def make_mount_cmd(onedir, twodir, oneimage, twoimage):
    return ['mkdir -p ' + onedir + ' ' + twodir,
            'mount -o rw ' + oneimage + ' ' + onedir,
            'mount -o rw ' + twoimage + ' ' + twodir]

def make_umount_cmd(onedir, twodir):
    return ['umount ' + onedir,
            'umount ' + twodir]

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: %s img1 img2" % sys.argv[0])
        sys.exit(1)
    if os.name == "posix":
        pathsep = "/"
    elif os.name == "nt":
        pathsep = "\\"
    else:
        sys.exit(1)

    (oneimage, twoimage) = sys.argv[1], sys.argv[2]
    if oneimage.endswith('.img') and twoimage.endswith('.img'):
        execute(make_umount_cmd(onedir, twodir))
        for cmd in make_mount_cmd(onedir, twodir, oneimage, twoimage):
            print(cmd)
            success, out, error_msg = execute(cmd)
            if not success:
                print(error_msg)
                sys.exit(1)
    elif os.path.isfile(oneimage) and os.path.isfile(twoimage): 
        one_result_check, one_result, one_errors = is_apk_file(oneimage, validate=True)
        if one_result_check:
            two_result_check, two_result, two_errors = is_apk_file(twoimage, validate=True)
        else:
            one_result = md5sum(oneimage)
            two_result = md5sum(twoimage)
        print("onefile %s:::: %s:" % (oneimage, one_result))
        print("twofile %s:::: %s:" % (twoimage, two_result))
        if  one_result != two_result:
            print("File %s in both targets but does not match!\n" % onedir)
        else:
            print("Exact match!")
        sys.exit(0)
    else:
        print("please check the input param!")
        sys.exit(1)

    subdirs = walkdirs(onedir, twodir)
    setinfo = complists(onedir, twodir)
    outp(setinfo, onedir, twodir)
    for subdir in subdirs:
        setinfo = complists(onedir + subdir, twodir + subdir)
        outp(setinfo, onedir + subdir, twodir + subdir)

    for cmd in make_umount_cmd(onedir, twodir):
        success, out, error_msg = execute(cmd)
        if not success:
            print(error_msg)
            sys.exit(1)

    print("\n\n\n\n\n")
    print("**************************************************")
    print("**************** Comparing Result ****************")
    print("**************************************************")
    print("Unique files in %s :" % oneimage)
    print("###########################")
    for item in oneimage_unique_items:
        print("%s " % item)
    print("###########################\n\n\n")

    print("Unique files in %s :" % twoimage)
    print("###########################")
    for item in twoimage_unique_items:
        print("%s " % item)
    print("###########################\n\n\n")

    print("Mismatch files:")
    print("###########################")
    for item in global_mismatch_result:
        print("%s " % item)
    print("###########################")
