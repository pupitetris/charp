#!/bin/sh

POSTDATA='login='$2'&res='$3'&params='$4

tmp=/tmp/tmp-$RANDOM.test
wget --post-data=$POSTDATA $1/request -O $tmp
cat $tmp
rm -f $tmp

