#!/bin/bash

relName="$1"
gitHash=$(git log --pretty=%h -1)
zipName="$relName-$gitHash.zip"

git archive -o $zipName HEAD
echo $zipName