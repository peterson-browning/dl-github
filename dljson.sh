#!/bin/bash

json=`curl -s https://api.github.com/repos/peterson-browning/hello-world/releases/latest`
#echo $json

prop='browser_download_url'

picurl=`echo $json | sed 's/\\\\\//\//g' | sed 's/[]{}[]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop | cut -d":" -f2- | sed -e 's/^ *//g' -e 's/ *$//'`
echo Downloading: $picurl

dlName=${picurl##*/}
echo Saving as: ./$dlName

`curl -s -X GET -L $picurl -o $dlName`