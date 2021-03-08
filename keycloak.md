#Comandos para evitar que el login requiera https

https://stackoverflow.com/questions/30622599/https-required-while-logging-in-to-keycloak-as-admin

recordar que la ubicacion de keycloak es 
```console
/opt/jboss/keycloak/bin
```
docker exec -it {contaierID} bash
cd keycloak/bin
./kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user admin
./kcadm.sh update realms/master -s sslRequired=NONE


