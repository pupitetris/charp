#!/bin/sh

tmp=/tmp/tmp-$RANDOM.test
wget --post-data='login=testuser&res=user_auth&params=' http://www.myproject.local/request -O $tmp
cat $tmp
rm -f $tmp

