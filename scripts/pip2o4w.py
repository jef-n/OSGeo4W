#!/usr/bin/env python

import sys
import subprocess
import re
import tarfile

from os import makedirs, environ, sep, chdir
from os.path import abspath, join, isdir, isfile, exists

try:
    from win32file import GetLongPathName
except:
    def GetLongPathName(p):
        return p

packages = sys.argv[1:]

done = []
added = []

if 'OSGEO4W_ROOT' not in environ:
    print("OSGEO4W_ROOT not set")
    sys.exit(1)

if 'OSGEO4W_MAINTAINER' not in environ:
    print("OSGEO4W_MAINTAINER not set")
    sys.exit(1)

if 'OSGEO4W_REP' not in environ:
    print("OSGEO4W_REP not set")
    sys.exit(1)

try:
    rep = GetLongPathName(environ['OSGEO4W_REP']).replace(sep,'/')+'/'
except:
    rep = environ['OSGEO4W_REP'].replace(sep,'/')+'/'

if not isdir(rep):
    print("OSGEO4W repository not found at {}.".format(rep))
    sys.exit(1)

o4wroot = GetLongPathName(environ['OSGEO4W_ROOT']).replace(sep,'/')+'/'

chdir(o4wroot)


def listpkg():
    proc = subprocess.Popen(['python', '-m', 'pip', 'list'], stdout=subprocess.PIPE)
    if not proc:
        print("could not list packages. " + repr(proc))
        sys.exit(1)

    pkgverre = re.compile("^(.*) \((.*)\)\s*$")
    pkgver = {}

    while True:
        l = proc.stdout.readline().decode("utf-8")
        if not l:
            break

        m = pkgverre.match(l)
        if m:
            pkgver[m.group(1)] = m.group(2)

    proc.stdout.close()

    return pkgver


pkgver = listpkg()

prefix = re.compile("^" + re.escape(o4wroot), re.IGNORECASE)

if sys.version_info[0] == 3:
    python = "python3"
else:
    python = "python"

while packages:
    print("Remaining packages: {}".format(len(packages)))

    pkg = packages.pop(0)
    if pkg in done:
        print("Dependency cycle found. {} already done.".format(pkg))
        continue

    print("Run {}".format(pkg))
    proc = subprocess.Popen([python, '-m', 'pip', 'install', '--no-compile', '--upgrade', pkg], stdout=subprocess.PIPE)
    if not proc:
        print("{}: could not install.".format(pkg))
        sys.exit(1)

    while True:
        l = proc.stdout.readline()
        if not l:
            print("EOF")
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

    if pkg.startswith("http:") or pkg.startswith("https:"):
        print("Could not query package information from {}".format(pkg))
        sys.exit(1)

    done.append(pkg)

    proc = subprocess.Popen([python, '-m', 'pip', 'show', '-f', pkg], stdout=subprocess.PIPE)
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
            print("{}: Required property {} not found.".format(pkg, p))
            sys.exit(1)

    if not isinstance(props['Requires'], list):
        props['Requires'] = props['Requires'].split(", ")

    for p in ['Files', 'Requires']:
        if not isinstance(props[p], list):
            print("{}: Property {} should be a list.".format(pkg, p))
            sys.exit(1)

    if len(props['Files']) == 0:
        print("{}: File lists empty.".format(pkg))
        continue

    name = props['Name'].lower()

    packages.extend([i.lower() for i in props['Requires'] if i.lower() not in done])

    pname = packagename(name)

    d = join(rep, "x86_64" if sys.maxsize > 2**32 else "x86", "release", python, pname)

    tn = join(d, "{0}-{1}-{2}.tar.bz2".format(pname, props['Version'], 1))

    if not isdir(d):
        makedirs(d)

    if isfile(tn):
        # print("{}: Rebuilding package {}.".format(pkg, tn))
        print("{}: Package {} already exists.".format(pkg, tn))
        continue

    tf = tarfile.open(tn, "w:bz2")

    postinstall = None
    preremove = None
    has3py = False

    for f in map( lambda x: abspath(join(props['Location'], x)).replace(sep,'/'), props['Files']):
        if f.endswith(".pyc"):
            continue

        if not isfile(f):
            print("{}: WARNING: File {} missing".format(pkg, f))
            continue

        if f.endswith(".py") and sys.version_info[0] >= 3:
            has3py = True

        f = GetLongPathName(f)

        if f.endswith(".exe") and pkg in ['pip', 'setuptools']:
            exe = open(f, "rb")
            data = exe.read()
            exe.close()

            data2 = re.sub(
                b"#!.*\\\\python.?\\.exe",
                str.encode("#!@osgeo4w@\\\\bin\\\\{}".format('python.exe' if sys.version_info[0] < 3 else "python3.exe")),
                data
            )

            if data != data2:
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

    if has3py and not preremove:
        preremove = open("preremove.bat", "wb")

    if preremove:
        if has3py:
            preremove.write(str.encode("call %OSGEO4W_ROOT%\\bin\\py3_env.bat\n"))
            preremove.write(str.encode("python -B %PYTHONHOME%\\Scripts\\preremove-cached.py {}\n".format(pname)))

        preremove.close()
        tf.add("preremove.bat", "etc/preremove/{}.bat".format(pname))

    tf.close()

    sf = open(join(d, "setup.hint"), "wb")
    sf.write("""\
sdesc: "{0}"
ldesc: "{0}"
maintainer: {1}
category: Libs
requires: {2}-core{3}
""" .format(
            props['Summary'],
            environ['OSGEO4W_MAINTAINER'],
            python,
            (" " + " ".join(sorted(packagename(p) for p in props['Requires']))) if props['Requires'] else ""
        ).encode("utf-8")
    )
    sf.close()

    added.append(tn)
