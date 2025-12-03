#!/bin/sh

file=$1
property=$2

function getProperty {
   key=$1
   value=`cat $file | grep "$key" | cut -d'=' -f2 | sed 's/"//g'` 
   echo $value
}

if [ ! -e ${file} ] ; then
    echo "NO FILE: ${file}"
else
    echo $(getProperty "${property}")
fi
