export P=libjpeg
export V=9d
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R/$P-devel $R/${P}12 $R/${P}12-devel

cat <<EOF >$R/setup.hint
sdesc: "A library for manipulating JPEG image format files (transitional)"
ldesc: "A library for manipulating JPEG image format files (transitional)"
category: _obsolete
requires: libjpeg-turbo
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/${P}12/setup.hint
sdesc: "A library for manipulating JPEG image format files (transitional)"
ldesc: "A library for manipulating JPEG image format files (transitional)"
category: _obsolete
requires: libjpeg-turbo
external-source: $P
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/$P-devel/setup.hint
sdesc: "A library for manipulating JPEG image format files (transitional)"
ldesc: "A library for manipulating JPEG image format files (transitional)"
category: _obsolete
requires: libjpeg-turbo-devel
external-source: $P
maintainer: $MAINTAINER
EOF

cat <<EOF >$R/${P}12-devel/setup.hint
sdesc: "A library for manipulating JPEG image format files (transitional)"
ldesc: "A library for manipulating JPEG image format files (transitional)"
category: _obsolete
requires: libjpeg-turbo-devel
external-source: $P
maintainer: $MAINTAINER
EOF

for l in \
	$R/$P-$V-$B.txt \
	$R/$P-devel/$P-devel-$V-$B.txt \
	$R/${P}12-$V-$B.txt \
	$R/${P}12-devel-$V-$B.txt;
do
	cat <<EOF >$l
LEGAL ISSUES
============

In plain English:

1. We don't promise that this software works.  (But if you find any bugs,
   please let us know!)
2. You can use this software for whatever you want.  You don't have to pay us.
3. You may not pretend that you wrote this software.  If you use it in a
   program, you must acknowledge somewhere in your documentation that
   you've used the IJG code.

In legalese:

The authors make NO WARRANTY or representation, either express or implied,
with respect to this software, its quality, accuracy, merchantability, or
fitness for a particular purpose.  This software is provided "AS IS", and you,
its user, assume the entire risk as to its quality and accuracy.

This software is copyright (C) 1991-2020, Thomas G. Lane, Guido Vollbeding.
All Rights Reserved except as specified below.

Permission is hereby granted to use, copy, modify, and distribute this
software (or portions thereof) for any purpose, without fee, subject to these
conditions:
(1) If any part of the source code for this software is distributed, then this
README file must be included, with this copyright and no-warranty notice
unaltered; and any additions, deletions, or changes to the original files
must be clearly indicated in accompanying documentation.
(2) If only executable code is distributed, then the accompanying
documentation must state that "this software is based in part on the work of
the Independent JPEG Group".
(3) Permission for use of this software is granted only if the user accepts
full responsibility for any undesirable consequences; the authors accept
NO LIABILITY for damages of any kind.

These conditions apply to any software derived from or based on the IJG code,
not just to the unmodified library.  If you use our work, you ought to
acknowledge us.

Permission is NOT granted for the use of any IJG author's name or company name
in advertising or publicity relating to this software or products derived from
it.  This software may be referred to only as "the Independent JPEG Group's
software".

We specifically permit and encourage the use of this software as the basis of
commercial products, provided that all warranty or liability claims are
assumed by the product vendor.


The Unix configuration script "configure" was produced with GNU Autoconf.
It is copyright by the Free Software Foundation but is freely distributable.
The same holds for its supporting scripts (config.guess, config.sub,
ltmain.sh).  Another support script, install-sh, is copyright by X Consortium
but is also freely distributable.
EOF
done

tar -cjf $R/$P-$V-$B.tar.bz2 -T /dev/null 
tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 -T /dev/null
tar -cjf $R/${P}12/${P}12-$V-$B.tar.bz2 -T /dev/null
tar -cjf $R/${P}12-devel/${P}12-devel-$V-$B.tar.bz2 -T /dev/null
tar -C .. -cjf $R/$P-$V-$B-src.tar.bz2 osgeo4w/package.sh

endlog
