/* A Bison parser, made by GNU Bison 2.7.12-4996.  */

/* Bison interface for Yacc-like parsers in C

      Copyright (C) 1984, 1989-1990, 2000-2013 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

#ifndef YY_YY_INIPARSE_HH_INCLUDED
# define YY_YY_INIPARSE_HH_INCLUDED
/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     STRING = 258,
     SETUP_TIMESTAMP = 259,
     SETUP_VERSION = 260,
     PACKAGEVERSION = 261,
     INSTALL = 262,
     SOURCE = 263,
     SDESC = 264,
     LDESC = 265,
     LICENSE = 266,
     CATEGORY = 267,
     DEPENDS = 268,
     REQUIRES = 269,
     APATH = 270,
     PPATH = 271,
     INCLUDE_SETUP = 272,
     EXCLUDE_PACKAGE = 273,
     DOWNLOAD_URL = 274,
     T_PREV = 275,
     T_CURR = 276,
     T_TEST = 277,
     MD5 = 278,
     INSTALLEDSIZE = 279,
     MAINTAINER = 280,
     PRIORITY = 281,
     DESCTAG = 282,
     DESCRIPTION = 283,
     FILESIZE = 284,
     ARCHITECTURE = 285,
     SOURCEPACKAGE = 286,
     MD5LINE = 287,
     RECOMMENDS = 288,
     PREDEPENDS = 289,
     SUGGESTS = 290,
     CONFLICTS = 291,
     REPLACES = 292,
     PROVIDES = 293,
     PACKAGENAME = 294,
     STRTOEOL = 295,
     PARAGRAPH = 296,
     EMAIL = 297,
     COMMA = 298,
     OR = 299,
     NL = 300,
     AT = 301,
     OPENBRACE = 302,
     CLOSEBRACE = 303,
     EQUAL = 304,
     GT = 305,
     LT = 306,
     GTEQUAL = 307,
     LTEQUAL = 308,
     OPENSQUARE = 309,
     CLOSESQUARE = 310,
     BINARYPACKAGE = 311,
     BUILDDEPENDS = 312,
     STANDARDSVERSION = 313,
     FORMAT = 314,
     DIRECTORY = 315,
     FILES = 316,
     MESSAGE = 317,
     AUTODEP = 318,
     ARCH = 319,
     RELEASE = 320
   };
#endif
/* Tokens.  */
#define STRING 258
#define SETUP_TIMESTAMP 259
#define SETUP_VERSION 260
#define PACKAGEVERSION 261
#define INSTALL 262
#define SOURCE 263
#define SDESC 264
#define LDESC 265
#define LICENSE 266
#define CATEGORY 267
#define DEPENDS 268
#define REQUIRES 269
#define APATH 270
#define PPATH 271
#define INCLUDE_SETUP 272
#define EXCLUDE_PACKAGE 273
#define DOWNLOAD_URL 274
#define T_PREV 275
#define T_CURR 276
#define T_TEST 277
#define MD5 278
#define INSTALLEDSIZE 279
#define MAINTAINER 280
#define PRIORITY 281
#define DESCTAG 282
#define DESCRIPTION 283
#define FILESIZE 284
#define ARCHITECTURE 285
#define SOURCEPACKAGE 286
#define MD5LINE 287
#define RECOMMENDS 288
#define PREDEPENDS 289
#define SUGGESTS 290
#define CONFLICTS 291
#define REPLACES 292
#define PROVIDES 293
#define PACKAGENAME 294
#define STRTOEOL 295
#define PARAGRAPH 296
#define EMAIL 297
#define COMMA 298
#define OR 299
#define NL 300
#define AT 301
#define OPENBRACE 302
#define CLOSEBRACE 303
#define EQUAL 304
#define GT 305
#define LT 306
#define GTEQUAL 307
#define LTEQUAL 308
#define OPENSQUARE 309
#define CLOSESQUARE 310
#define BINARYPACKAGE 311
#define BUILDDEPENDS 312
#define STANDARDSVERSION 313
#define FORMAT 314
#define DIRECTORY 315
#define FILES 316
#define MESSAGE 317
#define AUTODEP 318
#define ARCH 319
#define RELEASE 320



#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif

extern YYSTYPE yylval;

#ifdef YYPARSE_PARAM
#if defined __STDC__ || defined __cplusplus
int yyparse (void *YYPARSE_PARAM);
#else
int yyparse ();
#endif
#else /* ! YYPARSE_PARAM */
#if defined __STDC__ || defined __cplusplus
int yyparse (void);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */

#endif /* !YY_YY_INIPARSE_HH_INCLUDED  */
