#!/bin/bash

export LC_ALL=C
export LANG=C
export LANGUAGE=en_US.UTF-8



# fonts color
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
bold(){
    echo -e "\033[1m\033[01m$1\033[0m"
}



function getImage(){

if [ -n $1 ]; then

    fullname=$(basename -- "$1")
    echo "fullname: $fullname"

    extension="${fullname##*.}"
    echo "extension: $extension"

    filename="${fullname%.*}"
    echo "filename: $filename"


    set -x #echo on


    rembg $1 -o ./img/output/$filename-default10-u2net.$extension -m u2net
    rembg $1 -o ./img/output/$filename-default10-u2netp.$extension -m u2netp
    rembg $1 -o ./img/output/$filename-ae10.$extension -a -ae 10
    rembg $1 -o ./img/output/$filename-ae2.$extension -a -ae 2
    rembg $1 -o ./img/output/$filename-ae4.$extension -a -ae 4
    rembg $1 -o ./img/output/$filename-ae6.$extension -a -ae 6
    rembg $1 -o ./img/output/$filename-ae8.$extension -a -ae 8
    rembg $1 -o ./img/output/$filename-ae12.$extension -a -ae 12
    rembg $1 -o ./img/output/$filename-ae14.$extension -a -ae 14
    rembg $1 -o ./img/output/$filename-ae16.$extension -a -ae 16
    rembg $1 -o ./img/output/$filename-ae18.$extension -a -ae 18
    rembg $1 -o ./img/output/$filename-ae20.$extension -a -ae 20
    rembg $1 -o ./img/output/$filename-ae25.$extension -a -ae 25
    rembg $1 -o ./img/output/$filename-ae30.$extension -a -ae 30



    rembg $1 -o ./img/output/$filename-af240.$extension -a -af 240
    rembg $1 -o ./img/output/$filename-af120.$extension -a -af 120
    rembg $1 -o ./img/output/$filename-af140.$extension -a -af 140
    rembg $1 -o ./img/output/$filename-af160.$extension -a -af 160
    rembg $1 -o ./img/output/$filename-af180.$extension -a -af 180
    rembg $1 -o ./img/output/$filename-af200.$extension -a -af 200
    rembg $1 -o ./img/output/$filename-af220.$extension -a -af 220
    rembg $1 -o ./img/output/$filename-af240.$extension -a -af 240


    rembg $1 -o ./img/output/$filename-ab10.$extension -a -ab 10
    rembg $1 -o ./img/output/$filename-ab2.$extension -a -ab 2
    rembg $1 -o ./img/output/$filename-ab4.$extension -a -ab 4
    rembg $1 -o ./img/output/$filename-ab6.$extension -a -ab 6
    rembg $1 -o ./img/output/$filename-ab8.$extension -a -ab 8
    rembg $1 -o ./img/output/$filename-ab12.$extension -a -ab 12
    rembg $1 -o ./img/output/$filename-ab14.$extension -a -ab 14
    rembg $1 -o ./img/output/$filename-ab16.$extension -a -ab 16


    rembg $1 -o ./img/output/$filename-az1000.$extension -a -az 1000
    rembg $1 -o ./img/output/$filename-az600.$extension -a -az 600
    rembg $1 -o ./img/output/$filename-az800.$extension -a -az 800
    rembg $1 -o ./img/output/$filename-az900.$extension -a -az 900
    rembg $1 -o ./img/output/$filename-az1100.$extension -a -az 1100
    rembg $1 -o ./img/output/$filename-az1200.$extension -a -az 1200
    rembg $1 -o ./img/output/$filename-az1400.$extension -a -az 1400
    rembg $1 -o ./img/output/$filename-az1800.$extension -a -az 1800

    set +x #echo on

fi


}


green "$1"

getImage "./img/test1.jpg"
getImage "./img/test2.jpg"
getImage "./img/test3.jpg"

getImage "./img/test4.jpg"
getImage "./img/test5.png"

getImage "./img/test6.jpg"
getImage "./img/test7.jpg"


