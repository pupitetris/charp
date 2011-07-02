#!/bin/sh
# This file is part of the CHARP project.
#
# Copyright © 2011
#   Free Software Foundation Europe, e.V.,
#   Talstrasse 110, 40217 Dsseldorf, Germany
#
# Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

# Workarounds a broncas que genera el architect. Esto para que no saque warnings a la hora de convertir a SQL.

# No definir nombres para secuencias que ni se van a usar.
sed 's/autoIncrement="false" autoIncrementSequenceName="[^"]\+" /autoIncrement="false" /g'
