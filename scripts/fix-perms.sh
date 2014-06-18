#!/bin/sh

chgrp -R Usuarios .
chmod 600 mysql/conf/my.cnf
chmod 600 mysql/conf/my-su.cnf
