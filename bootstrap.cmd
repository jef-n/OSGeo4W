if not exist scripts mkdir scripts

if defined CI echo ::group::Installing cygwin
if not exist scripts/setup-x86_64.exe curl --output scripts/setup-x86_64.exe https://cygwin.com/setup-x86_64.exe
scripts\setup-x86_64.exe ^
	-qnNdOW ^
	-R %CD%/cygwin ^
	-s http://cygwin.mirror.constant.com ^
	-l %TEMP%/cygwin ^
	-P "bison,flex,poppler,doxygen,git,unzip,tar,diffutils,patch,curl,wget,flip,p7zip,make,osslsigncode,mingw64-x86_64-gcc-core,catdoc,enscript,mingw64-x86_64-binutils,perl-Data-UUID,ruby=2.6.4-1,perl-YAML-Tiny"
if defined CI echo ::endgroup::

copy bootstrap.sh cygwin\tmp
cygwin\bin\bash /tmp/bootstrap.sh %*
