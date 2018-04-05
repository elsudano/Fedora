#!/bin/bash
# Titulo:       Configuración Webmin
# Fecha:        05/04/18
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción:  Configura el FirewallD de cualquier maquina para abrir el puerto de Webmin
# Opciones: Ninguna
# Uso: webmin-open-firewalld.sh

# Fichero de configuración de SELinux
SELINUX_FILE=/etc/selinux/config

# opción para tener en cuenta posibles modificaciones anteriores
firewall-cmd --reload >/dev/null 2>&1
# Mostrar las zonas activas
ACTIVE_ZONE=$(firewall-cmd --get-active-zone | head -n1)
# Borramos el servicio que ya existe
firewall-cmd --permanent --delete-service=webmin
# Creamos el servicio para WebMin
firewall-cmd --permanent --new-service=webmin
# añadimos el puerto al servicio
firewall-cmd --permanent --service=webmin --add-port=10000/tcp
firewall-cmd --permanent --service=webmin --add-port=10000/udp
# añadimos el servicio a la zona activa
firewall-cmd --permanent --zone=$ACTIVE_ZONE --add-service=webmin
# opción para tener en cuenta posibles modificaciones anteriores
firewall-cmd --reload >/dev/null 2>&1
# desactivamos el SELinux tambien
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' $SELINUX_FILE
