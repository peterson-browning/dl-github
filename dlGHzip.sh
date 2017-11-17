#!/bin/bash

repoName="$1"
#repoName='peterson-browning/hello-world'

echo Checking repository status...
res=`curl -s -w %{http_code} https://api.github.com/repos/$repoName/releases/latest`
resCode=${res: -3}
res=${res:0:${#string}-3}

if [ $resCode = "404" ]
then
	#Change the color to red and print error message and exit
	echo -e "\e[31m"
	echo "HTTP Error Code: $resCode"
	echo "$res"
	echo "Repository not found (check spelling & try again)"
	echo 
	echo "Note repository should have the format <repo>/<project>"
	echo "   e.g. peterson-browning/hello-world"
	echo 
	echo "Also ensure the repo is PUBLIC and actually has releases!"
	exit 1
elif [ $resCode = "403" ]
then
	#Change the color to red and print error message and exit
	echo -e "\e[31m"
	echo "HTTP Error Code: $resCode"
	echo "$res"
	echo "Forbidden -- Access Denied, or Rate Limit Exceeded"
	exit 1
elif [ $resCode != "200" ]
then
	#Change the color to red and print error message and exit
	echo -e "\e[31m"
	echo "HTTP Error Code: $resCode"
	echo "$res"
	echo "Unable to access repository..."
	exit 1
fi

#Change color to Cyan and go
echo -e "\e[36m"
echo Getting latest release from repo: $repoName

#Get the JSON output from the latest release which will have A TON of info, including the address of where we can download the latest release .zip file
json=`curl -s https://api.github.com/repos/$repoName/releases/latest`
#e.g See "latest.json" for an example or `echo $json`

#The following JSON property is the "key" for where we will find the address of the .zip file 
zipKey='browser_download_url'

#Extract the value ($zipurl) using the "key" ($key) from the JSON ($json) info
zipurl=`echo $json | sed 's/\\\\\//\//g' | sed 's/[]{}[]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $zipKey | cut -d":" -f2- | sed -e 's/^ *//g' -e 's/ *$//'`
#e.g. https://github.com/peterson-browning/hello-world/releases/download/V0.0.3/V0.0.3.zip

#Peel off the file name ($zipName) from the end of the $zipurl
zipName=${zipurl##*/}
#e.g. V0.0.3.zip

#Actually download the .zip file and save it to $zipName
echo Downloading: $zipurl
curl -s -X GET -L $zipurl -o $zipName
#e.g. Downloading: https://github.com/peterson-browning/hello-world/releases/download/V0.0.3/V0.0.3.zip

#Peel off the release name ($relName)
tagKey='tag_name'
relName=`echo $json | sed 's/\\\\\//\//g' | sed 's/[]{}[]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $tagKey | cut -d":" -f2- | sed -e 's/^ *//g' -e 's/ *$//'`
#e.g. V0.0.3

#Unzip the downloaded file and place the contents in ./$relName
echo Unzipping to: ./$relName/$zipName
unzip -o -d ./$relName $zipName

#Clean up/remove the original zip file
rm $zipName
