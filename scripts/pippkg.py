# !/usr/bin/env python3

"""
environment variables
P:            package name (prefix with python3-)
V:            version
wheel:        install wheel instead of download
OSGEO4W_ROOT: private install directory
MAINTAINER:   OSGeo4W maintainer
OSGEO4W_REP:  local osgeo4w repository
adddepends:   additional (eg. non-python) dependencies
addsrcfiles:  additional packaging files
"""

import sys
import subprocess
import re
import tarfile
import os

from os.path import abspath, join, isdir, isfile


def system(cmd):
    print(f"SYSTEM:{cmd}", file=sys.stderr)
    return os.system(cmd)


if os.name == 'nt':
    from win32file import GetLongPathName
else:
    def GetLongPathName(p):
        return p

if 'OSGEO4W_ROOT' not in os.environ:
    print("OSGEO4W_ROOT not set", file=sys.stderr)
    sys.exit(1)

if 'MAINTAINER' not in os.environ:
    print("MAINTAINER not set", file=sys.stderr)
    sys.exit(1)

if 'OSGEO4W_REP' not in os.environ:
    print("OSGEO4W_REP not set", file=sys.stderr)
    sys.exit(1)

if 'P' not in os.environ:
    print("P not set", file=sys.stderr)
    sys.exit(1)

try:
    rep = GetLongPathName(os.environ['OSGEO4W_REP']).replace(os.sep, '/') + '/'
except Exception:
    rep = os.environ['OSGEO4W_REP'].replace(os.sep, '/') + '/'

if not isdir(rep):
    print(f"OSGEO4W repository not found at {rep}.", file=sys.stderr)
    sys.exit(1)

o4wroot = GetLongPathName(os.environ['OSGEO4W_ROOT']).replace(os.sep, '/') + '/'

prefix = re.compile("^" + re.escape(o4wroot), re.IGNORECASE)

mainpkg = os.environ["P"]
if not mainpkg.startswith("python3-"):
    print(f"{pkg}: python3- prefix missing", file=sys.stderr)
    sys.exit(1)

pkgs = [p for p in os.environ['PACKAGES'].split(' ') if p.startswith("python3-")]
builddepends = os.environ['BUILDDEPENDS'].split(' ')

mainpkg = mainpkg[8:]
v = os.environ["V"]

if 'wheel' in os.environ:
    pkgv = os.environ['wheel']
else:
    pkgv = mainpkg if v == "pip" else f"{mainpkg}=={v}"

print(f"Packaging {pkgv}", file=sys.stderr)

argv = ['python3', '-m', 'pip', '-v', 'install']
argv.extend(sys.argv[1:])
argv.append(pkgv)
print(f"PIP:{' '.join(argv)}", file=sys.stderr)
proc = subprocess.Popen(argv, stdout=subprocess.PIPE, encoding="utf-8")
if not proc:
    print("{pkgv}: could not install.", file=sys.stderr)
    sys.exit(1)

ipkgs=[]
while True:
    line = proc.stdout.readline()
    if not line:
        break

    print(f"L:{line}", end='')

#    m = re.search(f'Collecting (.*)==(.*) from', line, re.IGNORECASE)
#    if m:
#        print(f"{m.group(1)} (Version {m.group(2)}) installed from {mainpkg}", file=sys.stderr)
#        ipkgs.append(m.group(1))

proc.stdout.close()

system("python3 -m pip list")

try:
    os.unlink("pipped.env")
except IOError:
    pass

for pkg in pkgs:
    pkg = pkg[8:]
    system("python3 -m pip show -f {0} >%TEMP%/{0}.metadata".format(pkg))

    proc = subprocess.Popen(['python3', '-m', 'pip', 'show', '-f', pkg], stdout=subprocess.PIPE, encoding="utf-8")
    if not proc:
        print(f"{pkg}: Could not query package information.", file=sys.stderr)
        sys.exit(1)

    props = {}

    while True:
        line = proc.stdout.readline()
        if not line:
            break

        line = line.rstrip()
        if line == "---":
            continue

        if not line.startswith("  "):
            m = re.search('(\\S+):\\s*(.*)', line)
            if m:
                section, val = m.group(1), m.group(2)
                if val == "":
                    props[section] = []
                elif section not in props:
                    props[section] = val
                else:
                    print(f"{pkg}: property {section} already {props[section]} instead of {val} - ignored", file=sys.stderr)
                continue
        else:
            if not section:
                print(f"{pkg}: Line outside section: |{line}|", file=sys.stderr)
                sys.exit(1)

            try:
                props[section].append(line[2:])
            except Exception:
                props[section] += line[2:]

    proc.stdout.close()

    for p in ['Name', 'Version', 'Summary', 'Files', 'Requires', 'Location']:
        if p not in props:
            print(f"{pkg}: Required property {p} not found.\nprops: {repr(props)}", file=sys.stderr)
            sys.exit(1)

    if not isinstance(props['Requires'], list):
        props['Requires'] = list(map(str.lower, props['Requires'].split(", ")))

    for p in ['Files', 'Requires']:
        if not isinstance(props[p], list):
            print(f"{pkg}: Property {p} should be a list. {repr(props[p])}", file=sys.stderr)
            sys.exit(1)

    if len(props['Files']) == 0:
        print(f"{pkg}: File lists empty.", file=sys.stderr)
        sys.exit(1)

    name = props['Name'].lower()
    if name != pkg:
        if name.replace('_', '-') == pkg:
            name = pkg
        else:
            print(f"{pkg}: expected {pkg} instead of {name}", file=sys.stderr)
            sys.exit(1)

    pname = f'python3-{name}'

    d = join(rep, "x86_64", "release", 'python3', pname)
    if not isdir(d):
        os.makedirs(d)

    if props['Version'] == os.getenv("version_curr"):
        b=int(os.getenv("binary_curr")) + 1
    else:
        b=1

    while True:
        tn = join(d, f"{pname}-{props['Version']}-{b}.tar.bz2")
        if not isfile(tn):
            break
        b += 1

    tf = tarfile.open(tn, "w:bz2", format=tarfile.GNU_FORMAT)

    postinstall = None
    preremove = None
    haspy = False

    scriptspath = abspath(join(props['Location'], '..\\..\\Scripts')).replace(os.sep, '/') + "/"

    for f in map(lambda x: abspath(join(props['Location'], x)).replace(os.sep, '/'), props['Files']):
        if f.endswith(".pyc"):
            continue

        if not isfile(f):
            print(f"{pkg}: WARNING: File {f} missing", file=sys.stderr)
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
                print(f"{pkg}: Script {f} patched", file=sys.stderr)
                if not postinstall:
                    postinstall = open("postinstall.bat", "wb")

                if not preremove:
                    preremove = open("preremove.bat", "wb")

                postinstall.write(str.encode("textreplace -std -t {}\r\n".format(prefix.sub('', f))))
                preremove.write(str.encode("del {}\r\n".format(prefix.sub('', f).replace('/', '\\'))))

                f += ".tmpl"

                exe = open(f, "wb")
                exe.write(data2)
                exe.close()

        fr = prefix.sub('', f)
        if f == fr:
            print("{}: ERROR: Prefix {} missing from file {}".format(pkg, prefix.pattern, f), file=sys.stderr)
            raise BaseException("File {} for package {} missing".format(f, pkg))

        tf.add(f, fr)

    if postinstall:
        postinstall.close()
        tf.add("postinstall.bat", "etc/postinstall/{}.bat".format(pname))

    if haspy and not preremove:
        preremove = open("preremove.bat", "wb")

    if preremove:
        if haspy:
            preremove.write(str.encode("python3 -B \"%PYTHONHOME%\\Scripts\\preremove-cached.py\" {}\n".format(pname)))

        preremove.close()
        tf.add("preremove.bat", "etc/preremove/{}.bat".format(pname))

    tf.close()

    if props['Requires']:
        if "psycopg2-binary" in props['Requires']:
            props['Requires'].remove("psycopg2-binary")
            props['Requires'].append("psycopg2")
        props['Requires'] = sorted('python3-{}'.format(p.replace('_', '-')) for p in props['Requires'])

        s = set(props['Requires']) - set(builddepends) - set(pkgs)
        if s:
            print(f"{pkg}: Required packages missing in BUILDDEPENDS: {' '.join(s)}", file=sys.stderr)
            sys.exit(1)

        s = [p for p in [join('..', '..', p) for p in set(props['Requires']) - set(pkgs)] if not isdir(p)]
        if s:
            print(f"{pkg}: Required package directories missing: {' '.join(s)}", file=sys.stderr)
            sys.exit(1)

        props['Requires'] = " " + " ".join(props['Requires'])
    else:
        props['Requires'] = ""

    if 'externalsource' in os.environ:
        externalsource = os.environ['externalsource']
    elif pkg == mainpkg:
        tn = join(d, "{0}-{1}-{2}-src.tar.bz2".format(pname, props['Version'], b))
        if system("tar -C .. -cjf {0} osgeo4w/package.sh {1}".format(tn, os.environ.get("addsrcfiles", ''))) != 0:
            sys.exit(1)
        externalsource = None
    else:
        externalsource = 'python3-{}'.format(pkg.replace('_', '-'))

    sf = open(join(d, "setup.hint"), "wb")
    sf.write("""\
sdesc: "{0}"
ldesc: "{0}"
maintainer: {1}
category: Libs
requires: python3-core{2}{3}{4}
""" .format(
        props['Summary'],
        os.environ['MAINTAINER'],
        props['Requires'],
        (" " + os.environ['adddepends']) if 'adddepends' in os.environ else '',
        f"\nexternal-source: {externalsource}" if externalsource is not None else ''
    ).encode("utf-8"))
    sf.close()

    f = open("pipped.env", "a")
    f.write("P={}\nV={}\nB={}\n".format(pname, props['Version'], b))
    f.close()
