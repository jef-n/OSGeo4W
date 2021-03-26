#!/usr/bin/env python3

# environment variables
# P:            package name (prefix with python3-)
# V:            version
# wheel:        install wheel instead of download
# OSGEO4W_ROOT: private install directory
# MAINTAINER:   OSGeo4W maintainer
# OSGEO4W_REP:  local osgeo4w repository
# OSGEO4W_ROOT: OSGeo4W maintainer
# adddepends:   additional (eg. non-python) dependencies
# addsrcfiles:  additional packaging files

import sys
import subprocess
import re
import tarfile

from os import makedirs, environ, sep, system  # chdir
from os.path import abspath, join, isdir, isfile, exists

try:
    from win32file import GetLongPathName
except:
    def GetLongPathName(p):
        return p

if 'OSGEO4W_ROOT' not in environ:
    print("OSGEO4W_ROOT not set")
    sys.exit(1)

if 'MAINTAINER' not in environ:
    print("MAINTAINER not set")
    sys.exit(1)

if 'OSGEO4W_REP' not in environ:
    print("OSGEO4W_REP not set")
    sys.exit(1)

if 'P' not in environ:
    print("P not set")
    sys.exit(1)

try:
    rep = GetLongPathName(environ['OSGEO4W_REP']).replace(sep,'/')+'/'
except:
    rep = environ['OSGEO4W_REP'].replace(sep,'/')+'/'

if not isdir(rep):
    print("OSGEO4W repository not found at {}.".format(rep))
    sys.exit(1)

o4wroot = GetLongPathName(environ['OSGEO4W_ROOT']).replace(sep,'/')+'/'
# chdir(o4wroot)

prefix = re.compile("^" + re.escape(o4wroot), re.IGNORECASE)

pkg = environ["P"]
if not pkg.startswith("python3-"):
    print("{}: python3- prefix missing".format(pkg))
    sys.exit(1)

pkg = pkg[8:]
v = environ["V"]

if 'wheel' in environ:
    pkgv = environ['wheel']
else:
    pkgv = pkg if v == "pip" else "{}=={}".format(pkg, v)

print("Packaging {}".format(pkgv))

argv = ['python3', '-m', 'pip', 'install']
argv.extend(sys.argv[1:])
argv.append(pkgv)
proc = subprocess.Popen(argv, stdout=subprocess.PIPE)
if not proc:
    print("{}: could not install.".format(pkgv))
    sys.exit(1)

while True:
    l = proc.stdout.readline()
    if not l:
        break

    try:
        l = l.decode("utf-8")
    except:
        try:
            l = l.decode("cp1252")
        except:
            pass

    print("L:{}".format(l), end='')

    m = re.search('Collecting (.*)==(.*) from', l)
    if m:
        print("{} (Version {}) installed from {}".format(m.group(1), m.group(2), pkg))
        pkg = m.group(1)

proc.stdout.close()

print("python3 -m pip show -f {0} >%TEMP%/{0}.metadata".format(pkg))
system("python3 -m pip show -f {0} >%TEMP%/{0}.metadata".format(pkg))

proc = subprocess.Popen(['python3', '-m', 'pip', 'show', '-f', pkg], stdout=subprocess.PIPE)
if not proc:
    print("{}: Could not query package information.".format(pkg))
    sys.exit(1)

props = {}

while True:
    l = proc.stdout.readline()
    try:
        l = l.decode("utf-8")
    except:
        try:
            l = l.decode("cp1252")
        except:
            pass

    if not l:
        break

    l = l.rstrip()
    if l == "---":
        continue

    if not l.startswith("  "):
        m = re.search('(\S+):\s*(.*)', l)
        if m:
            section, val = m.group(1), m.group(2)
            if val == "":
                val = []
            props[section] = val
            continue
    else:
        if not section:
            print("{}: Line outside section: |{}|".format(pkg, l))
            sys.exit(1)

        props[section].append(l[2:])

proc.stdout.close()

for p in ['Name', 'Version', 'Summary', 'Files', 'Requires', 'Location']:
    if p not in props:
        print("{}: Required property {} not found.\nprops: {}".format(pkg, p, repr(props)))
        sys.exit(1)

if not isinstance(props['Requires'], list):
    props['Requires'] = list(map(str.lower, props['Requires'].split(", ")))

for p in ['Files', 'Requires']:
    if not isinstance(props[p], list):
        print("{}: Property {} should be a list. {}".format(pkg, p, repr(props[p])))
        sys.exit(1)

if len(props['Files']) == 0:
    print("{}: File lists empty.".format(pkg))
    sys.exit(1)

name = props['Name'].lower()
if name != pkg:
    print("{}: expected {} instead of {}".format(pkg, pkg, name))
    sys.exit(1)

pname = 'python3-{}'.format(name)

d = join(rep, "x86_64", "release", 'python3', pname)
if not isdir(d):
    makedirs(d)

b = 1
while True:
    tn = join(d, "{0}-{1}-{2}.tar.bz2".format(pname, props['Version'], b))
    if not isfile(tn):
        break
    b += 1

tf = tarfile.open(tn, "w:bz2")

postinstall = None
preremove = None
haspy = False

scriptspath = abspath(join(props['Location'], '..\\..\\Scripts')).replace(sep,'/') + "/"

for f in map( lambda x: abspath(join(props['Location'], x)).replace(sep,'/'), props['Files']):
    if f.endswith(".pyc"):
        continue

    if not isfile(f):
        print("{}: WARNING: File {} missing".format(pkg, f))
        continue

    if f.endswith(".py"):
        haspy = True

    isscript = f.startswith(scriptspath)

    f = GetLongPathName(f)

    if isscript:
        exe = open(f, "rb")
        data = exe.read()
        exe.close()

        data2 = re.sub(
            b"#!.*\\\\python.?\\.exe",
            str.encode("#!@osgeo4w@\\\\bin\\\\python3.exe"),
            data
        )

        if data != data2:
            print("{}: Script {} patched".format(pkg, f))
            if not postinstall:
                postinstall = open("postinstall.bat", "wb")

            if not preremove:
                preremove = open("preremove.bat", "wb")

            postinstall.write(str.encode("textreplace -std -t {}\r\n".format(prefix.sub('', f))))
            preremove.write(str.encode("del {}\r\n".format(prefix.sub('', f))))

            f += ".tmpl"

            exe = open(f, "wb")
            exe.write(data2)
            exe.close()

    fr = prefix.sub('', f)
    if f == fr:
        print("{}: ERROR: Prefix {} missing from file {}".format(pkg, prefix.pattern, f))
        raise BaseException("File {} for package {} missing".format(f, pkg))

    tf.add(f, fr)

if postinstall:
    postinstall.close()
    tf.add("postinstall.bat", "etc/postinstall/{}.bat".format(pname))

if haspy and not preremove:
    preremove = open("preremove.bat", "wb")

if preremove:
    if haspy:
        preremove.write(str.encode("python3 -B %PYTHONHOME%\\Scripts\\preremove-cached.py {}\n".format(pname)))

    preremove.close()
    tf.add("preremove.bat", "etc/preremove/{}.bat".format(pname))

tf.close()

sf = open(join(d, "setup.hint"), "wb")
sf.write("""\
sdesc: "{0}"
ldesc: "{0}"
maintainer: {1}
category: Libs
requires: python3-core{2}{3}
""" .format(
        props['Summary'],
        environ['MAINTAINER'],
        (" " + " ".join(sorted('python3-{}'.format(p) for p in props['Requires']))) if props['Requires'] else "",
        (" " + environ['adddepends']) if 'adddepends' in environ else ''
    ).encode("utf-8")
)
sf.close()

tn = join(d, "{0}-{1}-{2}-src.tar.bz2".format(pname, props['Version'], b))
if system("tar -C .. -cjf {0} osgeo4w/package.sh {1}".format(tn, environ.get("addsrcfiles", ''))) != 0:
    sys.exit(1)

f = open("pipped.env", "w")
f.write("P={}\nV={}\nB={}\n".format(pname, props['Version'], b))
f.close()
