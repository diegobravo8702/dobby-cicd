#! /bin/bash

#ENV="DEV"
ENV="PROD"

[[ $ENV == "DEV" ]] && SCRIPT_NAME="mvn-dev "       || SCRIPT_NAME="mvn-prod "
[[ $ENV == "DEV" ]] && PATH_LOG="../logs"           || PATH_LOG="/dobby/logs"
[[ $ENV == "DEV" ]] && LOG_FILE="dobby.log"         || LOG_FILE="dobby.log"

# p: pom path
# x: exchange dir
# n: project name
while getopts p:x:n: flag
do
    case "${flag}" in
        p) POM_PATH=${OPTARG};;
		x) EXC_PATH=${OPTARG};;
		n) PROJECT_NAME=${OPTARG};;
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

#log "mvn - 02 - resolve dependency - starting" &&
#mvn -f $POM_PATH -B dependency:resolve dependency:resolve-plugins &&
#log "mvn - 02 - resolve dependency - finished"

fecha=`date +"%Y%m%d-%H%M%S"`

log "mvn - 02 - install - starting" &&
mvn -f $POM_PATH clean install -e &&
log "mvn - 02 - install - finished" 

log "mvn - 03 - copiando - origen:  [$POM_PATH/*ear/target]" &&
log "mvn - 03 - copiando - destino: [$EXC_PATH/target_$PROJECT_NAME_$fecha]" &&
cp -r $POM_PATH/*ear/target $EXC_PATH/target_${PROJECT_NAME}_$fecha &&
log "mvn - 03 - copiando - listo" 

log "mvn - 04 - copiando - origen:  [$POM_PATH/*ear/target/*.ear]" &&
log "mvn - 04 - copiando - destino: [$EXC_PATH/to-deploy/]" &&
cp  $POM_PATH/*ear/target/*.ear $EXC_PATH/to-deploy/ &&
log "mvn - 04 - copiando a ruta para despliegue - listo" 

# ahora se debe crear este arvhivo:

		#batch
		#deploy /tmp/exchange/to-deploy/ci-ear-0.0.1.ear --force
		#run-batch

EAR=$(find $POM_PATH/*ear/target/ -name "*.ear" -printf "%f\n")

log "RESUTADO DE PRUEBA - ear:[$EAR]"

[[ -n "${EAR}" ]] &&
echo ""      >  $EXC_PATH/batch-deploy.cli &&
echo "batch" >> $EXC_PATH/batch-deploy.cli &&
echo "deploy /tmp/exchange/to-deploy/${EAR} --force" >> $EXC_PATH/batch-deploy.cli &&
echo "run-batch" >> $EXC_PATH/batch-deploy.cli



