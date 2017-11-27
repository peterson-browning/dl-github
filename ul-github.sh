#!/bin/bash

repoName="$1"
relName="$2"
TOKEN="$3"
#e.g. repoName='peterson-browning/dl-github'
#e.g. relName='V0.0.5'
#e.g. TOKEN='$GITHUB_TOKEN'


############################################################################
# Check Inputs
############################################################################

if [ "$repoName" = "" ] || [ "$relName" = "" ] || [ "$TOKEN" = "" ]
then
	#Change the color to yellow and print error message and exit
	echo -e "\e[33m"
	echo ERROR using ul-github.sh 
	echo 
	echo Inputs:
	echo [\$repoName] [\$relName] [\$TOKEN]
	echo
	echo Example:
	echo ./ul-github.sh peterson-browning/dl-github V0.0.13 \$GITHUB_TOKEN
	exit 1
fi

############################################################################
# Helper Functions
############################################################################

setJSONvalue () {
	local relName=$1
	local json="{ \"tag_name\": \"$relName\", \"target_commitish\": \"master\", \"name\": \"$relName\", \"body\": \"$relName\", \"draft\": false, \"prerelease\": false }"
	echo $json
}

getJSONvalue () {
	local jsonStr=$1  #input argument is the json string
	local tagKey=$2  #input argument is the tag
	local value=`echo $jsonStr | sed 's/\\\\\//\//g' | sed 's/[]{}[]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $tagKey | cut -d":" -f2- | sed -e 's/^ *//g' -e 's/ *$//'`
	echo $value
}


############################################################################
# MAIN Routine
############################################################################

echo Checking repository status...
res=`curl -s -w %{http_code} https://api.github.com/repos/$repoName/releases/latest`
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

json=$(setJSONvalue "$relName")
repoURL="https://api.github.com/repos/$repoName/releases"


#Use the API to POST the new release metadata
echo Creating $relName release for repo: $repoName
#curl -s -d $json -H "Content-Type: application/json" -X POST -L $repoURL
RES=$(curl -X POST -s -L -w "%{http_code}" -H "Authorization: token $TOKEN" -H "Content-Type: application/json" --data-ascii "$json"  $repoURL)
#e.g. Downloading: https://github.com/peterson-browning/hello-world/releases/download/V0.0.3/V0.0.3.zip
resCode=${RES: -3}
resText=${RES:0:${#string}-3}
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
elif [ $resCode != "201" ]
then
	#Change the color to red and print error message and exit
	echo -e "\e[31m"
	echo "HTTP Error Code: $resCode"
	echo "$resText"
	echo "Unable to access & POST to repository..."
	exit 1
fi

#Peel off the upload url ($ulURL)
tagKey='upload_url'
ulURL=$(getJSONvalue "$resText" "$tagKey")
#echo $ulURL

#Remove the text after the "{"
#ulURL=$(echo $ulURL | cut -d "{" -f1)


#Zip the appropriate contents & grab the name
zipName=`./zipGit.sh $relName`

#Add the Name
ulURL="$ulURL=$zipName"


echo Uploading zip to: $ulURL
RES=$(curl -X POST -s -L -w "%{http_code}" -H "Authorization: token $TOKEN" -H "Content-Type: application/zip" --data-binary @"$zipName" $ulURL)
resCode=${RES: -3}
resText=${RES:0:${#string}-3}
if [ $resCode = "201" ]
then
	echo "Success!"
elif [ $resCode != "201" ]
then
	#Change the color to red and print error message and exit
	echo -e "\e[31m"
	echo "HTTP Error Code: $resCode"
	echo "$resText"
	echo "Unable to access or POST to repository..."
	exit 1
fi


#Clean up/remove the original zip file
rm $zipName
exit 0