#!/bin/bash

repoName="$1"
relName="$2"  #OPTIONAL
#e.g. repoName='peterson-browning/dl-github'
#e.g. relName='V0.0.11'

############################################################################
# Helper Functions
############################################################################

getJSONvalue () {
	local jsonStr=$1  #input argument is the json string
	local tagKey=$2  #input argument is the tag
	local value=`echo $jsonStr | sed 's/\\\\\//\//g' | sed 's/[]{}[]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $tagKey | cut -d":" -f2- | sed -e 's/^ *//g' -e 's/ *$//'`
	echo $value
}


############################################################################
# MAIN Routine
############################################################################
relAPI="https://api.github.com/repos/$repoName/releases"

echo Checking repository status...
res=`curl -s -w %{http_code} $relAPI/latest`
resCode=${res: -3}
resText=${res:0:${#string}-3}

if [ $resCode = "404" ]
then
	#Change the color to red and print error message and exit
	echo -e "\e[31m"
	echo "HTTP Error Code: $resCode"
	echo "$resText"
	echo "Repository not found (check spelling & try again)"
	echo 
	echo "Note repository should have the format <repo>/<project>"
	echo "   e.g. peterson-browning/dl-github"
	echo 
	echo "Also ensure the repo is PUBLIC and actually has releases!"
	exit 1
elif [ $resCode = "403" ]
then
	#Change the color to red and print error message and exit
	echo -e "\e[31m"
	echo "HTTP Error Code: $resCode"
	echo "$resText"
	echo "Forbidden -- Access Denied, or Rate Limit Exceeded"
	exit 1
elif [ $resCode != "200" ]
then
	#Change the color to red and print error message and exit
	echo -e "\e[31m"
	echo "HTTP Error Code: $resCode"
	echo "$resText"
	echo "Unable to access repository..."
	exit 1
fi

#Change color to Cyan and go
echo -e "\e[36m"
if [ "$relName" = "" ] || [ "$relName" = "QUERY" ]
then
	echo Getting latest release from repo: $repoName

	#Get the JSON output from the latest release which will have A TON of info, including the address of where we can download the latest release .zip file
	json=`curl -s $relAPI/latest`
	#e.g See "latest.json" for an example or `echo $json`
else
	echo Getting $relName release from repo: $repoName
	#Get the JSON output from the latest release which will have A TON of info, including the address of where we can download the latest release .zip file
	json=`curl -s $relAPI/tags/$relName`
	#e.g See "latest.json" for an example or `echo $json`
fi
	
#The following JSON property is the "key" for where we will find the address of the .zip file 
zipKey='browser_download_url'

#Extract the value ($zipurl) using the "key" ($key) from the JSON ($json) info
zipurl=$(getJSONvalue "$json" "$zipKey")
#e.g. https://github.com/peterson-browning/hello-world/releases/download/V0.0.3/V0.0.3.zip
	
#Peel off the file name ($zipName) from the end of the $zipurl
zipName=${zipurl##*/}
#e.g. V0.0.3.zip

if [ "$zipName" = "" ]
then
	#Change the color to red and print error message and exit
	echo -e "\e[31m"
	echo "Nothing to download..."
	exit 1
fi

if [ "$relName" = "QUERY" ]
then
	echo Latest Release: $(getJSONvalue "$json" "tag_name")
	exit 0
fi
	
#Actually download the .zip file and save it to $zipName
echo Downloading: $zipName
curl -s -X GET -L $zipurl -o $zipName
#e.g. Downloading: https://github.com/peterson-browning/hello-world/releases/download/V0.0.3/V0.0.3.zip

#Peel off the release name ($relName)
tagKey='tag_name'
relName=$(getJSONvalue "$json" "$tagKey")
#e.g. V0.0.3

#Unzip the downloaded file and place the contents in ./$relName
echo Unzipping to: ./$relName/
unzip -o -d ./$relName $zipName

#Clean up/remove the original zip file
rm $zipName
exit 0
