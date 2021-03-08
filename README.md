# dobby-cicd


## Guia de despliegue

### Wildfly

#### jdbc driver
incluir en wildfly/batch.cli


``` console
batch
module add --name=sqlserver.jdbc --resources=/tmp/mssql-jdbc-9.2.0.jre8.jar --dependencies=javax.api,javax.transaction.api
/subsystem=datasources/jdbc-driver=sqlserver:add(driver-module-name=sqlserver.jdbc,driver-name=sqlserver,driver-class-name=com.microsoft.sqlserver.jdbc.SQLServerDriver)
run-batch
```

#### datasources
incluir en wildfly/batch.cli
reemplazar los campos por su respectivo valor:
- [datasourcename]
- [jndiname]
- [databaseuser]
- [databasepassword]
- [host]
- [port]
- [databasename]


``` console
batch
module add --name=sqlserver.jdbc --resources=/tmp/mssql-jdbc-9.2.0.jre8.jar --dependencies=javax.api,javax.transaction.api
/subsystem=datasources/jdbc-driver=sqlserver:add(driver-module-name=sqlserver.jdbc,driver-name=sqlserver,driver-class-name=com.microsoft.sqlserver.jdbc.SQLServerDriver)
/subsystem=datasources/data-source=[datasourcename]:add(jndi-name=[jndiname],enabled="true",use-java-context="true",driver-name=sqlserver,user-name=[databaseuser],password=[databasepassword],validate-on-match=true,background-validation=true,connection-url="jdbc:sqlserver://[host]:[port];databaseName=[databasename]")
run-batch
```


