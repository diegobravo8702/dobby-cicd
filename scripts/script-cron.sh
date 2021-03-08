#! /bin/bash


#ENV="DEV"
ENV="PROD"

[[ $ENV == "DEV" ]] && SCRIPT_NAME="cron-dev"                      || SCRIPT_NAME="cron-prod"
[[ $ENV == "DEV" ]] && PATH_GIT="../git"                           || PATH_GIT="/dobby/git"
[[ $ENV == "DEV" ]] && PATH_LOG="../logs"                          || PATH_LOG="/dobby/logs"
[[ $ENV == "DEV" ]] && LOG_FILE="dobby.log"                        || LOG_FILE="dobby.log"
[[ $ENV == "DEV" ]] && PATH_EXC="../exchange"                      || PATH_EXC="/dobby/exchange"
[[ $ENV == "DEV" ]] && PATH_REPOS="../exchange/repositories.js"    || PATH_REPOS="/dobby/exchange/repositories.js"
[[ $ENV == "DEV" ]] && STATUS_FILE="status"                        || STATUS_FILE="status"

#[[ $ENV == "DEV" ]] && ="" || echo =""

#Variables usadas en el analissi de cada repositorio
GIT_REPOSITORY_URL=""
GIT_REPOSITORY_NAME=""
GIT_BRANCH=""
GIT_TOKEN=""

GIT_ERROR=false
GIT_RECENT_COMMENT=""

# usada para detectar si hubo cambios en alguno de los repositorios, en caso de haberlos se modificara el archivo en wildfly que hace el despliegue

BACKUP_BATCH_DEPLOY=""
HUBO_CAMBIOS="NO"


# s: script name
# l: logs folder path
while getopts n:l: flag
do
    case "${flag}" in
        n) SCRIPT_NAME=${OPTARG};;
        l) PATH_LOG=${OPTARG};;
    esac
done


    
function batch_deploy_cli_backup {
    log "batch_deploy_cli_backup()"
    cp $PATH_EXC/batch-deploy.cli $PATH_EXC/batch-deploy.cli.back
}

function batch_deploy_cli_restore {
    log "batch_deploy_cli_restore()"
    cp $PATH_EXC/batch-deploy.cli.back $PATH_EXC/batch-deploy.cli
}

function batch_deploy_cli_new_start {
    log "batch_deploy_cli_new_start()"
    echo ""      >  $PATH_EXC/batch-deploy.cli &&
    echo "batch" >> $PATH_EXC/batch-deploy.cli
}

function batch_deploy_cli_new_end {
    log "batch_deploy_cli_new_end()"
    echo "run-batch" >> $PATH_EXC/batch-deploy.cli
}

function mvn_process {
    log "launching mvn process ..."
    log "command: ./script-mvn.sh -f ${PATH_GIT}/${GIT_REPOSITORY_NAME}"

    ##log "#A - $(git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ show-branch --no-name HEAD)"
    ##log "#B - $(git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ show-branch --no-name HEAD | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]')"
    ##log "#C - $(git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ show-branch --no-name HEAD | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]' | cut -c1-20)"

    GIT_COMMENT=$(git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ show-branch --no-name HEAD | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]' | cut -c1-20)

    /dobby/scripts/script-mvn.sh -p ${PATH_GIT}/${GIT_REPOSITORY_NAME} -n ${GIT_REPOSITORY_NAME} -c $GIT_COMMENT -x $PATH_EXC -b $(echo "$GIT_BRANCH" | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]') 
}

function git_clone {
	#log "git cloning ..."
	log "git clone -b ${GIT_BRANCH} https://${GIT_TOKEN}@${GIT_REPOSITORY_URL} ${PATH_GIT}/${GIT_REPOSITORY_NAME}/"
	git clone -b ${GIT_BRANCH} https://${GIT_TOKEN}@${GIT_REPOSITORY_URL} ${PATH_GIT}/${GIT_REPOSITORY_NAME}/
    mvn_process
}



function git_pull {

	#log "git reset --hard HEAD ..."
	git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ reset --hard HEAD
	#log "git clean -xffd ..."
	git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ clean -xffd

	#log "move to branch [${GIT_BRANCH}/${GIT_REPOSITORY_NAME}]..."
	git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ checkout ${GIT_BRANCH}

	#log "git pull ..."
	git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ pull
}

function git_current_commit_hash {
	echo $(git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ rev-parse HEAD)
}

function git_recent_coment {
    echo $(git -C ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ show-branch --no-name HEAD | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]' | cut -c1-20)
}

function log {
	currentDate=`date +"%Y-%m-%d %H:%M:%S %z"`

	if ! [ -d ${PATH_LOG}/ ]; then
		mkdir -p ${PATH_LOG}/
	fi

	echo ${currentDate}" | "${SCRIPT_NAME} " | "$1 >> ${PATH_LOG}/${LOG_FILE}
}

function reset_git_variables {
    GIT_REPOSITORY_URL=""
    GIT_REPOSITORY_NAME=""
    GIT_BRANCH=""
    GIT_TOKEN=""
    GIT_ERROR=false
    GIT_RECENT_COMMENT=""
}

function get_repository {
    #log "getting repository ... "
    # VERIFICANDO RUTA PARA FUENTES
    # si esta ya existe se hara el proceso de comparacion de hashes
    # en caso de no existir se crea el directorio y se hara el clone del proyecto
    if [ -d ${PATH_GIT}/${GIT_REPOSITORY_NAME}/ ]; then
        #log "Git verification - Directory exists: ${PATH_GIT}/"

        if [ "$(ls -A ${PATH_GIT}/${GIT_REPOSITORY_NAME}/)" ]; then 
            log "Git verification - Directory Not Empty"

            # Moverse a la rama

            GIT_HASH_BEFORE=$(git_current_commit_hash)
            #log "Git verification - pulling ..."
            git_pull
            GIT_HASH_AFTER=$(git_current_commit_hash)

            log "Git verification - Git commit hash bef : ${GIT_HASH_BEFORE}"
            log "Git verification - Git commit hash aft : ${GIT_HASH_AFTER}"
        else 
            log "Git verification - Directory Empty"
            log "Git verification - cloning ..."
            HUBO_CAMBIOS="SI"
            git_clone

        fi
    else
        log "Git verification - Path don't exists: ${PATH_GIT}/${GIT_REPOSITORY_NAME}/"
        log "Git verification - Making directory ..."
        mkdir -p ${PATH_GIT}/${GIT_REPOSITORY_NAME}/
        log "Git verification - cloning ..."
        HUBO_CAMBIOS="SI"
        git_clone

    fi

    # VERIFICANDO SI HUBO CAMBIOS
    if [ "$GIT_HASH_BEFORE" = "$GIT_HASH_AFTER" ]; then
        log "Git verification - No changes found"
    else
        HUBO_CAMBIOS="SI"
        log "Git verification - Git changes found, INVOCANDO A mvn_process ..."
        GIT_RECENT_COMMENT=$(git_recent_coment)
        mvn_process
    fi
}

function analize_repository {
    index=$1
    #cat ${PATH_REPOS} | jq  ".[${index}]"

    # se requiere que los repositorios contenga los 4 parametros requeridos
    GIT_REPOSITORY_URL=$(cat ${PATH_REPOS} | jq .[${index}].git_repository_url | tr -d '"')
    GIT_REPOSITORY_NAME=$(cat ${PATH_REPOS} | jq .[${index}].git_repository_name  | tr -d '"' | tr -d '/')
    GIT_BRANCH=$(cat ${PATH_REPOS} | jq .[${index}].git_branch  | tr -d '"')
    GIT_TOKEN=$(cat ${PATH_REPOS} | jq .[${index}].git_token  | tr -d '"')
    GIT_ERROR=false
    GIT_RECENT_COMMENT=""
    
    #log "GIT_REPOSITORY_URL: [${GIT_REPOSITORY_URL}]"
    #log "GIT_REPOSITORY_NAME: [${GIT_REPOSITORY_NAME}]"
    #log "GIT_BRANCH: [${GIT_BRANCH}]"
    #log "GIT_TOKEN: [${GIT_TOKEN}]"

    # -z string - True if the string length is zero.
    # -n string - True if the string length is non-zero.

    # TODO combinar las dos validaciones en una sola linea

    # notificando si el parametro no se recibió
    [[ "$GIT_REPOSITORY_URL" == "null" ]]  && log "ERROR - parametro no recibido - git_repository_url"  && GIT_ERROR=true
    [[ "$GIT_REPOSITORY_NAME" == "null" ]] && log "ERROR - parametro no recibido - git_repository_name" && GIT_ERROR=true
    [[ "$GIT_BRANCH" == "null" ]]          && log "ERROR - parametro no recibido - git_branch"          && GIT_ERROR=true
    [[ "$GIT_TOKEN" == "null" ]]           && log "ERROR - parametro no recibido - git_token"           && GIT_ERROR=true

    # notificando error cuando el parametro existe pero esta vacio
    [[ -z "$GIT_REPOSITORY_URL" ]]   && log "ERROR - parametro vacio - git_repository_url"  && GIT_ERROR=true
    [[ -z "$GIT_REPOSITORY_NAME" ]]  && log "ERROR - parametro vacio - git_repository_name" && GIT_ERROR=true
    [[ -z "$GIT_BRANCH" ]]           && log "ERROR - parametro vacio - git_branch"          && GIT_ERROR=true
    [[ -z "$GIT_TOKEN" ]]            && log "ERROR - parametro vacio - git_token"           && GIT_ERROR=true
    
    # log "analizando los resultados: [${GIT_ERROR}]"
    #((  $GIT_ERROR )) && log "no debe continuar porque hubo un error" && get_repository
    ( [ $GIT_ERROR == true ] && log "no debe continuar porque hubo un error" ) ||  get_repository

}

function notificar_bloqueo {
    log "notificando bloqueo"
    echo "LOCK" > ${PATH_EXC}/${STATUS_FILE}
}

function notificar_desbloqueo {
    log "notificando desbloqueo"
    echo "UNLOCK" > ${PATH_EXC}/${STATUS_FILE}
}

function actual_status {
    while IFS= read -r line; do
		status=($line)
	done < ${PATH_EXC}/${STATUS_FILE}
    echo "${status}"
}

function loop_repositories {
    notificar_bloqueo
    count=$(cat ${PATH_REPOS} | jq length)
    # log "repositorios encontrados : [${count}]"
    HUBO_CAMBIOS="NO"
    batch_deploy_cli_backup
    batch_deploy_cli_new_start

    for i in $(seq 0 $((count-1))); do 
        #log "estoy iterando el item [${i}]"
        reset_git_variables
        analize_repository ${i}
    done

    [[ "$HUBO_CAMBIOS" == "SI" ]] && batch_deploy_cli_new_end  && echo "SI HUBO CAMBIOS - se mantiene el nuevo batch_deploy_cli" || batch_deploy_cli_restore && echo "NO HUBO CAMBIOS - se restaura el backup de batch_deploy_cli"

    notificar_desbloqueo
}


status=$(actual_status)

[[ "$status" == "LOCK" ]] && echo "BLOQUEADO" || (echo "DESBLOQUEADO" && loop_repositories)


