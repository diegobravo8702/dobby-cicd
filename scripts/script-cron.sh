#! /bin/bash


#ENV="DEV"
ENV="PROD"

[[ $ENV == "DEV" ]] && SCRIPT_NAME="cron-dev"                      || SCRIPT_NAME="cron-prod"
[[ $ENV == "DEV" ]] && PATH_GIT="../git"                           || PATH_GIT="/dobby/git"
[[ $ENV == "DEV" ]] && PATH_LOG="../logs"                          || PATH_LOG="/dobby/logs"
[[ $ENV == "DEV" ]] && LOG_FILE="dobby.log"                        || LOG_FILE="dobby.log"
[[ $ENV == "DEV" ]] && PATH_REPOS="../exchange/repositories.js"    || PATH_REPOS="/dobby/exchange/repositories.js"

#[[ $ENV == "DEV" ]] && ="" || echo =""

#Variables usadas en el analissi de cada repositorio
GIT_REPOSITORY_URL=""
GIT_REPOSITORY_NAME=""
GIT_BRANCH=""
GIT_TOKEN=""


# s: script name
# l: logs folder path
while getopts n:l: flag
do
    case "${flag}" in
        n) SCRIPT_NAME=${OPTARG};;
        l) PATH_LOG=${OPTARG};;
    esac
done


function git_clone {
	log "git cloning ..."
	log "git clone -b ${GIT_BRANCH} https://${GIT_TOKEN}@${GIT_REPOSITORY_URL} ${PATH_GIT}/${GIT_REPOSITORY_NAME}/"
	git clone -b ${GIT_BRANCH} https://${GIT_TOKEN}@${GIT_REPOSITORY_URL} ${PATH_GIT}/${GIT_REPOSITORY_NAME}/
}



function git_pull {

	log "git reset --hard HEAD ..."
	git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ reset --hard HEAD
	log "git clean -xffd ..."
	git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ clean -xffd

	log "move to branch [${GIT_BRANCH}/${GIT_REPOSITORY_NAME}]..."
	git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ checkout ${GIT_BRANCH}

	log "git pull ..."
	git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ pull
}

function git_current_commit_hash {
	echo $(git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ rev-parse HEAD)
}

function log {
	currentDate=`date +"%Y-%m-%d %H:%M:%S %z"`

	if ! [ -d ${PATH_LOG}/ ]; then
		mkdir -p ${PATH_LOG}/
	fi

	echo ${currentDate}" | "${SCRIPT_NAME} " | "$1 >> ${PATH_LOG}/${LOG_FILE}
}

## TODO: validar si los campos son nulos
#function analize_repository {
#    index=$1
#    echo "-------------------------------------------"
#    echo "index $index"
#    #cat ${PATH_REPOS} | jq  ".[${index}]"
#
#    # se requiere que los repositorios contenga los 3 parametros requeridos
#    git_repository=$(cat ${PATH_REPOS} | jq ".[${index}].git_repository")
#    git_branch=$(cat ${PATH_REPOS} | jq ".[${index}].git_branch")
#    git_token=$(cat ${PATH_REPOS} | jq ".[${index}].git_token")
#    log "git_repository: [${git_repository}]"
#    log "git_branch: [${git_branch}]"
#    log "git_token: [${git_token}]"
#
#    [ ! -n "${git_repository}" ] && echo "git_repository Not NULL" || echo "git_repository NULL"
#
#    if [ -z "$git_repository" ]
#    then
#        echo "\$git_repository is empty [${git_repository}]"
#    else
#        echo "\$git_repository is NOT empty [${git_repository}]"
#    fi
#
#    if [ -n "${git_repository+set}" ]; then
#    echo "JAIL is set, possibly to the empty string"
#    fi
#
#}

function analize_repository {
    index=$1
    #cat ${PATH_REPOS} | jq  ".[${index}]"

    # se requiere que los repositorios contenga los 3 parametros requeridos
    GIT_REPOSITORY_URL=$(cat ${PATH_REPOS} | jq .[${index}].git_repository_url | tr -d '"')
    GIT_REPOSITORY_NAME=$(cat ${PATH_REPOS} | jq .[${index}].git_repository_name  | tr -d '"' | tr -d '/')
    GIT_BRANCH=$(cat ${PATH_REPOS} | jq .[${index}].git_branch  | tr -d '"')
    GIT_TOKEN=$(cat ${PATH_REPOS} | jq .[${index}].git_token  | tr -d '"')
    

    log "GIT_REPOSITORY_URL: [${GIT_REPOSITORY_URL}]"
    log "GIT_REPOSITORY_NAME: [${GIT_REPOSITORY_NAME}]"
    log "GIT_BRANCH: [${GIT_BRANCH}]"
    log "GIT_TOKEN: [${GIT_TOKEN}]"


    # VERIFICANDO RUTA PARA FUENTES
    # si esta ya existe se hara el proceso de comparacion de hashes
    # en caso de no existir se crea el directorio y se hara el clone del proyecto
    if [ -d ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ ]; then
        log "Git verification - Directory exists: ${PATH_GIT}/"

        if [ "$(ls -A ${PATH_GIT}/${GIT_REPOSITORY_NAME}/)" ]; then 
            log "Git verification - Directory Not Empty"

            # Moverse a la rama

            GIT_HASH_BEFORE=$(git_current_commit_hash)
            log "Git verification - pulling ..."
            git_pull
            GIT_HASH_AFTER=$(git_current_commit_hash)

            log "Git verification - Git commit hash bef : ${GIT_HASH_BEFORE}"
            log "Git verification - Git commit hash aft : ${GIT_HASH_AFTER}"
        else 
            log "Git verification - Directory Empty"
            log "Git verification - cloning ..."
            git_clone

        fi
    else
        log "Git verification - Path don't exists: ${PATH_GIT}/${GIT_REPOSITORY_NAME}/"
        log "Git verification - Making directory ..."
        mkdir -p ${PATH_GIT}/${GIT_REPOSITORY_NAME}/
        log "Git verification - cloning ..."
        git_clone

    fi

    # VERIFICANDO SI HUBO CAMBIOS
    if [ "$GIT_HASH_BEFORE" = "$GIT_HASH_AFTER" ]; then
        log "Git verification - No changes found"
    else
        log "Git verification - Git changes found, REALIZAR ALGO PORQUE HUBO CAMBIOS ..."
        log "Git verification - Git changes found, INVOCANDO A buildApp ..."
        buildApp
    fi



}

function loop_repositories {
    count=$(cat ${PATH_REPOS} | jq length)
    log "repositorios encontrados : [${count}]"

    for i in $(seq 0 $((count-1))); do 
        #log "estoy iterando el item [${i}]"
        analize_repository ${i}
    done
}

function buildApp {
	log "building app"
	# se mueve 
	# /home/diegobravo_dev/code/environment/temp/git
	#/bin/bash PATH_GIT./build.sh
	#mvn -B dependency:resolve dependency:resolve-plugins
}

log "revisando ..."
loop_repositories
