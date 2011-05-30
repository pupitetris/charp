#!/bin/sh
# Mata todos los scripts en Perl spawneados por cgi-fcgi, en cygwin.

if [ $(uname -o) != 'Cygwin' ]; then
    exit
fi

ps | grep '^ \+[0-9]\+ \+1 ' | grep perl | 
	while read i; do 
	    echo $i | tr ' ' $'\t'
	    kill `echo $i | awk '{print $1}'`
	done
