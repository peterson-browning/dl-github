#!/bin/bash
GIT_ZIP_LOC="https://github.com/geekcomputers/Python/archive/master.zip"
TMPFILE=thisTemp.zip


curl --location --insecure $GIT_ZIP_LOC -o $TMPFILE
unzip -o -d $pwd\requires $TMPFILE
rm $TMPFILE
