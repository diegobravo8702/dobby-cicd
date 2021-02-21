#! /bin/bash

SCRIPT_NAME="cron"
PATH_LOG="/dobby/logs/"
LOG_FILE="dobby.log"

# s: script name
# l: logs folder path
while getopts n:l: flag
do
    case "${flag}" in
        n) SCRIPT_NAME=${OPTARG};;
        l) PATH_LOG=${OPTARG};;
    esac
done




function log {
	currentDate=`date +"%Y-%m-%d %H:%M:%S %z"`

	if ! [ -d ${PATH_LOG}/ ]; then
		mkdir -p ${PATH_LOG}/
	fi

    echo ${currentDate}" | "${SCRIPT_NAME} " | "$1
	echo ${currentDate}" | "${SCRIPT_NAME} " | "$1 >> ${PATH_LOG}/${LOG_FILE}
}

log "revisando ..."