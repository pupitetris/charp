#!/bin/sh
# Kill all perl scripts spawned by cgi-fcgi on cygwin
# to drop database connections.

[ $(uname -o) != 'Cygwin' ] && exit

ps -a | grep perl | 
	while read i; do
	    ppid=$(awk '{print $2}' <<< $i)
	    [ "$ppid" = 1 ] || continue
	    tty=$(awk '{print $5}' <<< $i)
	    [ "$tty" = '?' ] || continue
	    echo Killing $i | sed 's/ \+/ /g'
	    kill $(awk '{print $1}' <<< $i)
	done
