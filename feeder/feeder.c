#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <sys/ioctl.h>
#include <sys/types.h>

#ifdef __CYGWIN__
  #define TIOCSTI 0x5412
#endif

void output( char* cmd );

void output( char *cmd ) {
    if ( cmd && strlen( cmd ) > 0 ) {
        size_t size = strlen( cmd );
        unsigned int i;
        char *c;
        for (i = 0; i < size; i++) {
            c = cmd + i;
            ioctl( 0, TIOCSTI, c );
        }
    }
}

int main( int argc, char *argv[] ) {
    int i, whole_len = 0;
    char *buf;
    for ( i = 1; i < argc; i ++ ) {
        whole_len += strlen( argv[ i ] ) + 1;
    }

    buf = ( char * ) malloc( sizeof( char ) * ( whole_len + 1 ) );
    if( !buf ) {
        return 102;
    }

    buf[ 0 ] = '\0';
    for ( i = 1; i < argc; i ++ ) {
        strcat( buf, argv[ i ] );
        strcat( buf, " " );
    }
    buf[ whole_len - 1 ] = '\r';

    output( buf );

    free( buf );

    return 0;
}
