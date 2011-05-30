#!/bin/sh
# Workarounds a broncas que genera el architect. Esto para que no saque warnings a la hora de convertir a SQL.

# No definir nombres para secuencias que ni se van a usar.
sed 's/autoIncrement="false" autoIncrementSequenceName="[^"]\+" /autoIncrement="false" /g'
