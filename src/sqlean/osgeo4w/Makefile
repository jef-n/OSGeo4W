CC=cl
CFLAGS=-DSQLEAN_VERSION=\"$(V)\"

all: sqlean.dll

crypto.dll: src/sqlite3-crypto.c $(wildcard src/crypto/*.c)
	$(CC) $(CFLAGS) $^ /link /dll /out:$@

define.dll: src/sqlite3-define.c $(wildcard src/define/*.c)
	$(CC) $(CFLAGS) $^ /link /dll /out:$@

fileio.dll: src/sqlite3-fileio.c $(wildcard src/fileio/*.c)
	$(CC) $(CFLAGS) $^ /link /dll /out:$@

fuzzy.dll:: src/sqlite3-fuzzy.c $(wildcard src/fuzzy/*.c)
	$(CC) $(CFLAGS) $^ /link /dll /out:$@

ipaddr.dll: src/sqlite3-ipaddr.c $(wildcard src/ipaddr/*.c)
	$(CC) $(CFLAGS) $^ /link /dll /out:$@ ws2_32.lib

math.dll: src/sqlite3-math.c $(wildcard src/math/*.c)
	$(CC) $(CFLAGS) $^ /link /dll /out:$@

stats.dll: src/sqlite3-stats.c $(wildcard src/stats/*.c)
	$(CC) $(CFLAGS) $^ /link /dll /out:$@

text.dll: src/sqlite3-text.c $(wildcard src/text/*.c) $(wildcard src/text/utf8/*.c)
	$(CC) $(CFLAGS) $^ /link /dll /out:$@

time.dll: src/sqlite3-time.c $(wildcard src/time/*.c)
	$(CC) $(CFLAGS) $^ /link /dll /out:$@

unicode.dll: src/sqlite3-unicode.c $(wildcard src/unicode/*.c)
	$(CC) $(CFLAGS) $^ /link /dll /out:$@

uuid.dll: src/sqlite3-uuid.c $(wildcard src/uuid/*.c)
	$(CC) $(CFLAGS) $^ /link /dll /out:$@

vsv.dll: src/sqlite3-vsv.c $(wildcard src/vsv/*.c)
	$(CC) $(CFLAGS) $^ /link /dll /out:$@

regexp.dll: src/sqlite3-regexp.c $(wildcard src/regexp/*.c) $(wildcard src/regexp/pcre2/*.c)
	$(CC) $(CFLAGS) /FIsrc/regexp/constants.h $^ /link /dll /out:$@

sqlean.dll: \
	src/sqlite3-sqlean.c \
	$(wildcard src/crypto/*.c) \
	$(wildcard src/define/*.c) \
	$(wildcard src/fileio/*.c) \
	$(wildcard src/fuzzy/*.c) \
	$(wildcard src/math/*.c) \
	$(wildcard src/stats/*.c) \
	$(wildcard src/text/*.c) $(wildcard src/text/utf8/*.c) \
	$(wildcard src/uuid/*.c) \
	$(wildcard src/time/*.c) \
	$(wildcard src/unicode/*.c) \
	$(wildcard src/vsv/*.c) \
	$(wildcard src/regexp/*.c) $(wildcard src/regexp/pcre2/*.c)
	$(CC) $(CFLAGS) /FIsrc/regexp/constants.h $^ /link /dll /out:$@
