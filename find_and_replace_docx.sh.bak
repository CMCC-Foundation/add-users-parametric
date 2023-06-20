#!/bin/bash

echo "FILE: ""$1"
echo "FILE OUT: ""$2"
echo "TOKENS: ""$3"
echo "REP TOKENS: ""$4"

tokens=($3)
rep_tokens=($4)

token_len="${#tokens[@]}"


echo "token len: ""${#tokens[@]}"

#for i in ${tokens[@]};
#do
#	echo "token: ""$(echo $i)"
#done

echo "rep token len: ""${#rep_tokens[@]}"

#for i in ${rep_tokens[@]};
#do
#    echo "rep token: ""$(echo $i)"
#done

FILE="$1"
FILE_OUT="$2"
#FIND="$3"
#REPLACE="$4"

unzip "$FILE" -d tmp #unzip

for i in $(seq 0 $(($token_len-1)));
do
    echo "token: ""${tokens[$i]}"
    echo "rep token: ""${rep_tokens[$i]}"
    echo "char count: ""$(echo "${tokens[$i]}" | wc -c)"
    sed -i "s/${tokens[$i]}/${rep_tokens[$i]}/g" tmp/word/document.xml #find/replace
done

#sed -i "s/SECRET/%SECRET%/g" tmp/word/document.xml

cd tmp && zip -r ../"$FILE_OUT" * && cd .. #zip
rm -rf tmp
