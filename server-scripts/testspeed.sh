#!/bin/bash

PROVIDERS=(#"testvelocidadeu.mismenet.net" \
"speedtestbcn.adamo.es" \
"speedtestbcn.adamo.es" \
"testvelocidad.eu/speed-test" \
"testvelocidad.eu/speed-test" \
"speedtest.conectabalear.com/ba/")

DEBUG=0

MIN=6 # minimum value for the longitude of random value of salt
MAX=8 # maximum value for the longitude of random value of salt
TIME_TO_MEASURE=15 # maximum timeout for taken mesaure

function download {
    DIFF=$(($MAX-$MIN+1))
    COMMAND="curl -w %{speed_download} -s --output /dev/null --max-time $TIME_TO_MEASURE"
    $COMMAND $1?$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w $(echo $(($(($RANDOM%$DIFF))+$MIN))) | head -n 1) >> $2
    echo "" >> $2
}

function average {
    # File temporal for taken all statistic download
    FILE=$(mktemp)
    BYTES=0
    # Launch all thread for download
    for P in ${PROVIDERS[@]}; do
        download "https://$P/download.bin" $FILE &
        sleep 0.1 # for no write in file in the same time
    done
    # add 2 seconds for calculate average of download
    TIME_TO_MEASURE=$(($TIME_TO_MEASURE+2))
    sleep $TIME_TO_MEASURE
    while read i; do
        i=${i%",000"} # clean decimals
        BYTES=$(($BYTES+i))
    done <$FILE;

    BITS=$((($BYTES*8)/1048576))
    BYTES=$(($BYTES/1048576))
    echo "Public IP: $(curl -s ifconfig.me)"
    echo "Average download speed: $BITS Mb/s, $BYTES MB/s"
}

# MAIN
average;