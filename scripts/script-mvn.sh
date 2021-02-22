#! /bin/bash

#ENV="DEV"
ENV="PROD"

[[ $ENV == "DEV" ]] && SCRIPT_NAME="mvn-dev "       || SCRIPT_NAME="mvn-prod "
[[ $ENV == "DEV" ]] && PATH_LOG="../logs"           || PATH_LOG="/dobby/logs"
[[ $ENV == "DEV" ]] && LOG_FILE="dobby.log"         || LOG_FILE="dobby.log"

# f: pom path
while getopts f: flag
do
    case "${flag}" in
        f) POM_PATH=${OPTARG};;
    esac
done


function log {
	currentDate=`date +"%Y-%m-%d %H:%M:%S %z"`

	if ! [ -d ${PATH_LOG}/ ]; then
		mkdir -p ${PATH_LOG}/
	fi

	echo ${currentDate}" | "${SCRIPT_NAME} " | "$1 >> ${PATH_LOG}/${LOG_FILE}
}

log "mvn - 00 - MVN_PATH: [${POM_PATH}]"

log "mvn - 01 - clean - starting" &&
mvn -f $POM_PATH clean &&
log "mvn - 01 - clean - finished"

log "mvn - 02 - resolve dependency - starting" &&
mvn -f $POM_PATH -B dependency:resolve dependency:resolve-plugins &&
log "mvn - 02 - resolve dependency - finished"

log "mvn - 03 - install - starting" &&
mvn -f $POM_PATH install &&
log "mvn - 03 - install - finished"