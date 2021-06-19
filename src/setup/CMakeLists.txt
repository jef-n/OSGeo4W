cmake_minimum_required(VERSION 3.16)

PROJECT(osgeo4w-setup)

SET(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

# TODO: retrieve from ChangeLog
FILE(WRITE ${CMAKE_BINARY_DIR}/setup_version.c "#define VERSION_PREFIX \"%%% setup-version\"\nstatic const char version_store[] = VERSION_PREFIX \" 2.579\";\nconst char *setup_version = version_store + sizeof (VERSION_PREFIX);\n")

INCLUDE(Flex)
FIND_FLEX()
IF (NOT FLEX_EXECUTABLE)
  MESSAGE(FATAL_ERROR "Couldn't find Flex")
ENDIF (NOT FLEX_EXECUTABLE)

INCLUDE(Bison)
FIND_BISON()

INCLUDE_DIRECTORIES(
  libgetopt++/include
  ${BZIP2_SRC}
  ${ZLIB_SRC}
  ${CMAKE_SOURCE_DIR}
)

IF(MSVC)
  ADD_DEFINITIONS(
    -DNOMINMAX
    -D_CRT_SECURE_NO_WARNINGS
    -DHAVE_STRING_H
    -Dstrcasecmp=_stricmp
    # -Dsnprintf=_snprintf
    -DOSGEO4W_MIRROR_URL="http://download.osgeo.org/osgeo4w/v2/mirrors.lst"
    -wd4996 # 'function': was declared deprecated
  )
  SET_SOURCE_FILES_PROPERTIES(PickView.cc
    PROPERTIES COMPILE_FLAGS -wd4355
    # C4355 'this' : used in base member initializer list
  )
  SET_SOURCE_FILES_PROPERTIES(${BZIP2_SRC}/bzlib.c ${BZIP2_SRC}/compress.c
    PROPERTIES COMPILE_FLAGS "-wd4267 -wd4244 -wd4996"
    # C4267 'var' : conversion from 'size_t' to 'type', possible loss of data
    # C4244 'conversion' conversion from 'type1' to 'type2', possible loss of data
    # C4996 'function': was declared deprecated
  )
ENDIF(MSVC)

SET(SRCS
  AntiVirus.cc
  archive.cc
  archive_tar.cc
  archive_tar_file.cc
  choose.cc
  compress.cc
  compress_bz.cc
  compress_gz.cc
  ConnectionSetting.cc
  ControlAdjuster.cc
  cygpackage.cc
  desktop.cc
  dialog.cc
  diskfull.cc
  download.cc
  Exception.cc
  express_package.cc
  filemanip.cc
  find.cc
  FindVisitor.cc
  fromcwd.cc
  geturl.cc
  ini.cc
  IniDBBuilderPackage.cc
  IniParseFeedback.cc
  IniParseFindVisitor.cc
  install.cc
  io_stream.cc
  io_stream_cygfile.cc
  io_stream_file.cc
  io_stream_memory.cc
  license.cc
  localdir.cc
  LogFile.cc
  LogSingleton.cc
  main.cc
  mkdir.cc
  mklink2.cc
  mount.cc
  msg.cc
  net.cc
  netio.cc
  nio-file.cc
  nio-ftp.cc
  nio-http.cc
  nio-ie5.cc
  package_db.cc
  package_meta.cc
  package_source.cc
  package_version.cc
  PackageSpecification.cc
  PickCategoryLine.cc
  PickPackageLine.cc
  PickView.cc
  postinstall.cc
  postinstallresults.cc
  prereq.cc
  proppage.cc
  propsheet.cc
  root.cc
  ScanFindVisitor.cc
  script.cc
  simpsock.cc
  source.cc
  SourceSetting.cc
  splash.cc
  state.cc
  site.cc
  String++.cc
  threebar.cc
  UserSettings.cc
  win32.cc
  window.cc

  ${CMAKE_BINARY_DIR}/setup_version.c

  libgetopt++/src/BoolOption.cc
  libgetopt++/src/StringOption.cc
  libgetopt++/src/StringArrayOption.cc
  libgetopt++/src/GetOption.cc
  libgetopt++/src/OptionSet.cc
  libgetopt++/src/Option.cc

  csu_util/MD5Sum.cc
  csu_util/rfc1738.cc
  csu_util/version_compare.cc

  libmd5-rfc/md5.c

  ${BZIP2_SRC}/bzlib.c
  ${BZIP2_SRC}/crctable.c
  ${BZIP2_SRC}/blocksort.c
  ${BZIP2_SRC}/compress.c
  ${BZIP2_SRC}/crctable.c
  ${BZIP2_SRC}/decompress.c
  ${BZIP2_SRC}/huffman.c
  ${BZIP2_SRC}/randtable.c
  ${BZIP2_SRC}/unzcrash.c

  ${ZLIB_SRC}/adler32.c
  ${ZLIB_SRC}/compress.c
  ${ZLIB_SRC}/crc32.c
  ${ZLIB_SRC}/deflate.c
  ${ZLIB_SRC}/gzclose.c
  ${ZLIB_SRC}/gzlib.c
  ${ZLIB_SRC}/gzread.c
  ${ZLIB_SRC}/gzwrite.c
  ${ZLIB_SRC}/infback.c
  ${ZLIB_SRC}/inffast.c
  ${ZLIB_SRC}/inflate.c
  ${ZLIB_SRC}/inftrees.c
  ${ZLIB_SRC}/trees.c
  ${ZLIB_SRC}/uncompr.c
  ${ZLIB_SRC}/zutil.c

  res.rc
)

ADD_BISON_FILES(SRCS iniparse.yy)
ADD_FLEX_FILES(SRCS inilex.ll)

ADD_EXECUTABLE(osgeo4w-setup WIN32 ${SRCS})
SET_PROPERTY(TARGET osgeo4w-setup PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")

TARGET_LINK_LIBRARIES(osgeo4w-setup wsock32 shlwapi comctl32 ole32 wsock32 wininet comdlg32 gdi32)
