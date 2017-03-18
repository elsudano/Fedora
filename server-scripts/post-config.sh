#!/bin/bash
# Titulo:       Configuración Inicial
# Fecha:        23/12/16
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción:  Muestra la configuración actual y da opciones para cambiarla
# Opciones: Ninguna
# Uso: initial-config.sh


# VARIABLES ESTATICAS
DEPENDS=(cat) # Dependencias necesarias
DIRS=(/usr/bin /usr/sbin /bin) # Directorios de busqueda
MASKS_CIDR=(32 31 30 29 28 27 26 25 24 23 22)
MASKS_DEC=(255.255.255.255 255.255.255.254 255.255.255.252 255.255.255.248 255.255.255.240 255.255.255.224 255.255.255.192 255.255.255.128 255.255.255.0 255.255.254.0 255.255.252.0)

# VARIABLES GLOBALES
TEST_IP=62.15.168.50
DNF_CONF_FILE=/etc/dnf/dnf.conf
NTP_CONFIG_FILE=/etc/ntp.conf
TEMP_FILE=/tmp/file.tmp

# FUNCIONES

# Función para deter la ejecución con o sin mensaje
# parámetro de entrada $1 == --with-msg para poner mensaje (opcional)
# #parámetro de entrada $2 == cadena de texto con el mensaje (opcional)
function pause() {
    if [[ $1 == "--with-msg" ]] && [[ $2 != "" ]]; then
        read -p "$2";
    elif [[ $1 == "--with-msg" ]]; then
        read -p "Presione Enter para continuar o Ctrl+C para cancelar.";
    else
        read -s -t 5
    fi
}

# Función para saber si se esta utilizando root
function is_root {
    if [[ "$(whoami)" != "root" ]]; then
        echo
        echo "  Tiene que ejecutar este script con permisos de administrador";
        echo
        exit;
    fi
}

# Funcion de wrapper para find
# parámetro de entrada $1 lo que queremos buscar
function buscar(){
    if [ $1 != "" ]; then
        local retval=$(find / -name $1)
    else
        echo "Faltán parámetros para buscar"
    fi
    echo $retval
}

# Función que se encarga de buscar las dependencias
function check_depends() {
    for depend in ${DEPENDS[@]}
    do
        hit=0
        for dir in ${DIRS[@]}
        do
            if [ -x "$dir/$depend" ]; then
                echo "Dependencia encontrada: $depend"
                hit=1
                break;
            fi
        done
        if [ $hit == 0 ]; then
            echo "Dependencia NO encontrada: $depend"
        fi
    done
}

#Función que se encarga de configurar las exclusiones de paquetes para dnf
function config_dnf(){
    echo "Si desea actualizar el sistema por completo tiene que realizar la actualización, desde el panel de control de webmin"
    echo "exclude=kernel* mariadb* postgresql* apache* httpd* mod_ssl* mysql* php* java*" >> $DNF_CONF_FILE
}

#Función que se encarga de instalar el monitor de sistema htop
function install_htop(){
    echo "Instalación de monitor htop"
    dnf -y install htop.x86_64
}

#Función que se encarga de instalar y configura el demonio para la sincronización de la hora
function config_ntpd(){
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
