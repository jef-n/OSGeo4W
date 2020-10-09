/******************************************************************************
 *
 * Project:  OSGeo4W
 * Purpose:  Replace key paths, etc in text files as part of update process.
 * Author:   Frank Warmerdam, warmerdam@pobox.com
 *
 ******************************************************************************
 * Copyright (c) 2008, Frank Warmerdam
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 ****************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

/************************************************************************/
/*                               usage()                                */
/************************************************************************/

void Usage()

{
    printf( "Usage: textreplace -sf <source file> -df <destination file>\n"
            "                   [-map <source text> <destination text>]*\n"
            " or\n"
            "       textreplace -std -t <destination file>\n" );
    exit( 1 );
}

/************************************************************************/
/*                                main()                                */
/************************************************************************/

int main( int argc, char ** argv )

{
    const char *src_filename = NULL;
    const char *dst_filename = NULL;
    const char *map_src[1000];
    const char *map_dst[1000];
    int map_count = 0;
    int i, target_flag = 0;
    int src_filesize, dst_filesize, dst_filemax;
    char *src_filedata, *dst_filedata;
    FILE *fp;

/* -------------------------------------------------------------------- */
/*      Processing commandline options.                                 */
/* -------------------------------------------------------------------- */
    for( i = 1; i < argc; i++ )
    {
        if( strcmp(argv[i],"-sf") == 0 && i < argc-1 )
            src_filename = argv[++i];
        else if( strcmp(argv[i],"-df") == 0 && i < argc-1 )
            dst_filename = argv[++i];
        else if( strcmp(argv[i],"-t") == 0 && i < argc-1 )
        {
            dst_filename = argv[++i];
            src_filename = (char *) malloc(strlen(dst_filename)+10);
            strcpy( (char *) src_filename, dst_filename );
            strcat( (char *) src_filename, ".tmpl" );
            target_flag = 1;
        }
        else if( strcmp(argv[i],"-std") == 0 )
        {
            if( map_count > 998 )
            {
                fprintf( stderr, "too many mappings!\n" );
                exit( 1 );
            }

            map_src[map_count] = "@osgeo4w@";
            map_dst[map_count++] = getenv("OSGEO4W_ROOT");
            map_src[map_count] = "@osgeo4w_msys@";
            map_dst[map_count++] = getenv("OSGEO4W_ROOT_MSYS");

            if( map_dst[map_count-2] == NULL
                || map_dst[map_count-1] == NULL )
            {
                fprintf( stderr,
                         "Missing OSGEO4W_ROOT or OSGEO4W_ROOT_MSYS environment variable.\n" );
                map_count -= 2;
            }
        }
        else if( strcmp(argv[i],"-map") == 0 && i < argc-2 )
        {
            if( map_count > 999 )
            {
                fprintf( stderr, "too many mappings!\n" );
                exit( 1 );
            }

            map_src[map_count] = argv[++i];
            map_dst[map_count++] = argv[++i];

            if( map_src[map_count-1][0] != '@' )
            {
                fprintf( stderr,
                         "Currently map patterns must start with '@'.\n" );
                exit( 1 );
            }
        }
        else
            Usage();
    }

    if( src_filename == NULL || dst_filename == NULL || map_count == 0 )
        Usage();

/* -------------------------------------------------------------------- */
/*      Read the entire input file.                                     */
/* -------------------------------------------------------------------- */
    fp = fopen( src_filename, "rb" );

    if( fp == NULL && target_flag == 1 )
    {   // fallback to replacing source with -t
        src_filename = dst_filename;
        fp = fopen( src_filename, "rb" );
    }

    if( fp == NULL )
    {
        fprintf( stderr, "Failed to open source file '%s'.\n%s\n",
                 src_filename,
                 strerror( errno ) );
        exit( 1 );
    }

    fseek( fp, 0, SEEK_END );
    src_filesize = ftell( fp );
    fseek( fp, 0, SEEK_SET );

    src_filedata = (char *) malloc(src_filesize+1);
    if( src_filedata == NULL )
    {
        fprintf( stderr, "out of memory allocating buffer.\n" );
        exit( 1 );
    }

    if( fread( src_filedata, 1, src_filesize, fp ) != src_filesize )
    {
        fprintf( stderr, "%s: Failed to read whole input file.\n",
                 src_filename );
        perror( "fread" );
        exit( 1 );
    }
    fclose( fp );

/* -------------------------------------------------------------------- */
/*      Allocate an output buffer with substantial extra room.          */
/* -------------------------------------------------------------------- */
    dst_filesize = 0;
    dst_filemax = (int) (src_filesize * 1.1) + 1000000;

    dst_filedata = (char *) malloc(dst_filemax+1);
    if( dst_filedata == NULL )
    {
        fprintf( stderr, "out of memory allocating dest buffer.\n" );
        exit( 1 );
    }

/* -------------------------------------------------------------------- */
/*      Process data from source to destination, with remapping as      */
/*      needed.  For now we depend on the source map strings            */
/*      starting with a '@' so we can scan through fairly simply.       */
/*      This could be generalized later.                                */
/* -------------------------------------------------------------------- */
    for( i = 0; i < src_filesize; i++ )
    {
        int map_i;

        /* normal no further checking case */
        if( src_filedata[i] != '@' && dst_filesize < dst_filemax )
        {
            dst_filedata[dst_filesize++] = src_filedata[i];
            continue;
        }

        for( map_i = 0; map_i < map_count; map_i++ )
        {
            int src_map_len = strlen( map_src[map_i] );

            if( src_map_len > src_filesize - i )
                continue;

            if( memcmp( map_src[map_i], src_filedata + i, src_map_len ) != 0 )
                continue;

            break;
        }

        /* no match, copy over */
        if( map_i == map_count )
        {
            if( dst_filesize == dst_filemax )
            {
                fprintf( stderr, "Destination buffer grew too large.\n" );
                exit( 1 );
            }

            dst_filedata[dst_filesize++] = src_filedata[i];
            continue;
        }

        /* Got a match - apply transformation */
        if( dst_filesize+strlen(map_dst[map_i]) > dst_filemax )
        {
            fprintf( stderr, "Destination buffer grew too large.\n" );
            exit( 1 );
        }

        memcpy( dst_filedata + dst_filesize, map_dst[map_i],
                strlen( map_dst[map_i] ) );
        dst_filesize += strlen( map_dst[map_i] );
        i += strlen( map_src[map_i] ) - 1;
    }

/* -------------------------------------------------------------------- */
/*      Write out modified file.                                        */
/* -------------------------------------------------------------------- */
    fp = fopen( dst_filename, "wb" );
    if( fp == NULL )
    {
        fprintf( stderr, "Failed to open destination file '%s'.\n%s\n",
                 dst_filename,
                 strerror( errno ) );
        exit( 1 );
    }

    if( fwrite( dst_filedata, 1, dst_filesize, fp ) != dst_filesize )
    {
        fprintf( stderr, "%s: Failed to write whole output file.\n",
                 src_filename );
        perror( "fwrite" );
        exit( 1 );
    }

    fclose( fp );

    exit( 0 );
}
