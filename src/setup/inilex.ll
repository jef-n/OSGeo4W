%{
/*
 * Copyright (c) 2000, Red Hat, Inc.
 *
 *     This program is free software; you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation; either version 2 of the License, or
 *     (at your option) any later version.
 *
 *     A copy of the GNU General Public License can be found at
 *     http://www.gnu.org/
 *
 * Written by DJ Delorie <dj@cygnus.com>
 * Maintained by Robert Collins <rbtcollins@hotmail.com>
 *
 */

/* tokenize the setup.ini files.  We parse a string which we've
   previously downloaded.  The program must call ini_init() to specify
   that string. */

#include "win32.h"
#include <string.h>

#include "ini.h"
#include "iniparse.hh"
#include "String++.h"
#include "IniParseFeedback.h"
#include "msg.h"

#define YY_INPUT(buf,result,max_size) { result = ini_getchar(buf, max_size); }

static int ini_getchar(char *buf, int max_size);
static void ignore_line (void);

%}

/*%option debug */
%option nounput
%option noyywrap
%option yylineno
%option never-interactive

%x descriptionstate
%x eolstate

STR	[!a-zA-Z0-9_./:\+~-]+

%%

[0123456789abcdef]{32,32}       {
    yylval = (char *) new unsigned char[16];
    for (int i=0; i< 16; ++i)
      ((unsigned char *) yylval) [i] = 0;
    for (int i=0; i< 32; ++i)
      {
	unsigned char val = (unsigned char) yytext[i];
	if (val > '9')
	  val = val - 'a' + 10;
	else
	  val = val - '0';
	((unsigned char *) yylval) [i / 2] += val << ((i % 2) ? 0 : 4);
      }
    return MD5;
}

\"[^"]*\"		{ yylval = new char [strlen (yytext+1) + 1];
			  strcpy (yylval, yytext+1);
			  yylval[strlen (yylval)-1] = 0;
			  return STRING; }

"setup-timestamp:"	return SETUP_TIMESTAMP;
"setup-version:"	return SETUP_VERSION;
"arch:"			return ARCH;
"release:"		return RELEASE;
"Package:"		return PACKAGENAME;
[vV]"ersion:"		return PACKAGEVERSION;
"install:"|"Filename:"	return INSTALL;
"source:"		return SOURCE;
"sdesc:"		return SDESC;
"ldesc:"		return LDESC;
"license:"		return LICENSE;
"message:"		return MESSAGE;
"autodep:"		return AUTODEP;
"Description:"		BEGIN (descriptionstate); return DESCTAG;
"Size:"			return FILESIZE;
"MD5sum:"		return MD5LINE;
"Installed-Size:"	return INSTALLEDSIZE;
"Maintainer:"		BEGIN (eolstate); return MAINTAINER;
"Architecture:"		return ARCHITECTURE;
"Source:"		return SOURCEPACKAGE;
"Binary:"		return BINARYPACKAGE;
"Build-Depends:"	return BUILDDEPENDS;
"Build-Depends-Indep:"	return BUILDDEPENDS; /* technicallyincorrect :[ */
"Standards-Version:"	return STANDARDSVERSION;
"Format:"		return FORMAT;
"Directory:"		return DIRECTORY;
"Files:"		return FILES;

"category:"		return CATEGORY;
"Section:"		return CATEGORY;
"Priority:"		return PRIORITY;
"requires:"		return REQUIRES;
"Depends:"		return DEPENDS;
"Pre-Depends:"		return PREDEPENDS;
"Recommends:"		return RECOMMENDS;
"Suggests:"		return SUGGESTS;
"Conflicts:"		return CONFLICTS;
"Replaces:"		return REPLACES;
"Provides:"		return PROVIDES;

"apath:"		return APATH;
"ppath:"		return PPATH;

"include-setup:"	return INCLUDE_SETUP;

"download-url:"		return DOWNLOAD_URL;

^{STR}":"		ignore_line ();

"[curr]"		return T_CURR;
"[test]"		return T_TEST;
"[exp]"			return T_TEST;
"[prev]"		return T_PREV;

"("			return OPENBRACE;
")"			return CLOSEBRACE;
"["			return OPENSQUARE;
"]"			return CLOSESQUARE;
"<<"			return LT;
">>"			return GT;
">="			return GTEQUAL;
"<="			return LTEQUAL;
">"			return GT;
"<"			return LT;
"="                     return EQUAL;
\,			return COMMA;
"|"			return OR;
"@"			return AT;

{STR}"@"{STR}		{ yylval = new char [strlen(yytext) + 1];
    			  strcpy (yylval, yytext);
			  return EMAIL; }
{STR}			{ yylval = new char [strlen(yytext) + 1];
  			  strcpy (yylval, yytext);
			  return STRING; }

[ \t\r]+		/* do nothing */;

^"#".*\n		/* do nothing */;
<descriptionstate>[^\n]+	{ yylval = new char [strlen(yytext) + 1];
    				  strcpy (yylval, yytext);
				  return STRTOEOL; }
<descriptionstate>\n	{ return NL; }
<descriptionstate>"\n"+	{BEGIN(INITIAL); return PARAGRAPH;}
<eolstate>[^\n]+	{return STRING; }
<eolstate>\n		{BEGIN(INITIAL); return NL; }

\n			{ return NL; }
.			{ return *yytext;}

%%

#include "io_stream.h"

static io_stream *input_stream = 0;
extern IniDBBuilder *iniBuilder;
static IniParseFeedback *iniFeedback;
std::string current_ini_name, yyerror_messages;
int yyerror_count;

void
ini_init(io_stream *stream, IniDBBuilder *aBuilder, IniParseFeedback &aFeedback)
{
  input_stream = stream;
  iniBuilder = aBuilder;
  iniFeedback = &aFeedback;
  YY_FLUSH_BUFFER;
  yylineno = 1;
  yyerror_count = 0;
  yyerror_messages.clear ();
}

static int
ini_getchar(char *buf, int max_size)
{
  if (input_stream)
    {
      ssize_t len = input_stream->read (buf, max_size);
      if (len < 1)
        {
	  len = 0;
	  input_stream = 0;
	}
      else
        iniFeedback->progress (input_stream->tell(), input_stream->get_size());
      return len;
    }
  return 0;
}

static void
ignore_line ()
{
  char c;
  while ((c = yyinput ()))
    {
      if (c == EOF)
	return;
      if (c == '\n')
	return;
    }
}

int
yyerror (const std::string& s)
{
  char tmp[16];
  sprintf (tmp, "%d", yylineno - (!!YY_AT_BOL ()));

  std::string e = current_ini_name + " line " + tmp + ": " + s;

  if (!yyerror_messages.empty ())
    yyerror_messages += "\n";

  yyerror_messages += e;
  msg( "%s\n", e.c_str ());
  yyerror_count++;
  /* TODO: is return 0 correct? */
  return 0;
}
