#!/bin/bash
# Titulo:       Configuración Inicial
# Fecha:        23/12/16
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción:  Muestra la configuración actual y da opciones para cambiarla
# Opciones: Ninguna
# Uso: initial-config.sh

# VARIABLES ESTATICAS DEL SCRIPT
# poner esto como el resto de scripts DEPENDS=(cat) # Dependencias necesarias

# VARIABLES GLOBALES DEL SCRIPT
TEST_IP=8.8.8.8
DNF_CONF_FILE=/etc/dnf/dnf.conf
NTP_CONFIG_FILE=/etc/ntp.conf
TEMP_FILE=/tmp/file.tmp

# INCLUDES
path="$(dirname "$0")"
source "$path/functions-depends.sh"

#Función que se encarga de configurar las exclusiones de paquetes para dnf
function config_dnf {
    echo "Si desea actualizar el sistema por completo tiene que realizar la actualización, desde el panel de control de webmin"
    echo "exclude=kernel* mariadb* postgresql* apache* httpd* mod_ssl* mysql* php* java*" >> $DNF_CONF_FILE
}

#Función que se encarga de instalar el monitor de sistema htop
function install_htop {
    echo "Instalación de monitor htop"
    dnf -y install htop.x86_64
}

#Función que se encarga de instalar y configura el demonio para la sincronización de la hora
function config_ntpd {
    echo "Instalación de NTPd"
    dnf -y install ntp.x86_64
    dnf -y install ntpdate.x86_64
    echo "Abriendo firewalld para NTPd"
    firewall-cmd --add-service=ntp --permanent
    firewall-cmd --reload
    echo "Activando Demonio"
    systemctl enable ntpd
    systemctl start ntpd
    if [ -e $NTP_CONFIG_FILE ];then
        cp --backup=numbered $NTP_CONFIG_FILE $NTP_CONFIG_FILE.bak
    fi
    echo "Configurando servidores..."
    echo "server hora.roa.es iburst" >> $NTP_CONFIG_FILE
    echo "Comprobando el servicio"
    ntpq -p
}

function production_permissions {
    # Este es el comando que hay que usar para poner los permisos de las carpetas
    # y los archivos de un servidor web de producción
    #find $DIR -type d -exec chmod 754 {} \; # --> para las carpetas
    #find $DIR -type f -exec chmod 644 {} \; # --> para los ficheros
}

# Función para presentar el Menú
# Sin parámetros de entrada
function menu() {
    clear;
    echo
    echo "           ****************************************"
    echo "           *          Select one option           *"
    echo "           * 1.- Config DNF                       *"
    echo "           * 2.- Install htop                     *"
    echo "           * 3.- Install and Config NTPd          *"
    echo "           *                                      *"
    echo "           * 0.- Exit                            *"
    echo "           ****************************************"
    echo
    read -p "           Select one option: " option
    case $option in
        0)
        exit;
        ;;
        1)
        config_dnf;
        pause;
        menu;
        ;;
        2)
        install_htop;
        pause;
        menu;
        ;;
        3)
        config_ntpd;
        pause;
        menu;
        ;;
        *)
        echo "This option is not allowed";
        pause;
        menu;
        ;;
    esac
}
is_root;
menu;
