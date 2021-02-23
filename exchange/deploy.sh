#!/bin/bash

JBOSS_HOME=/opt/jboss/wildfly
JBOSS_CLI=$JBOSS_HOME/bin/jboss-cli.sh
JBOSS_MODE=${1:-"standalone"}
JBOSS_CONFIG=${2:-"$JBOSS_MODE.xml"}



echo "==> Executing..."
#$JBOSS_CLI -c --file=`dirname "$0"`/deploy.cli  --connect
$JBOSS_CLI -c --file=/tmp/exchange/batch-deploy.cli  --connect


