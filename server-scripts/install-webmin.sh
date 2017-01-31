#!/bin/bash
# Titulo:       Configuración e instalación de Webmin
# Fecha:        23/12/16
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción:  Instalación y configuración de WebMin
# Opciones: Ninguna
# Uso: install-webmin.sh


# VARIABLES ESTATICAS
DEPENDS=(dnf git perl wget rpm) # Dependencias necesarias
DIRS=(/usr/bin /usr/sbin /bin) # Directorios de busqueda
MASKS_CIDR=(32 31 30 29 28 27 26 25 24 23 22)
MASKS_DEC=(255.255.255.255 255.255.255.254 255.255.255.252 255.255.255.248 255.255.255.240 255.255.255.224 255.255.255.192 255.255.255.128 255.255.255.0 255.255.254.0 255.255.252.0)

# VARIABLES GLOBALES
TEST_IP=62.15.168.50
REPO_WEBMIN_FILE=/etc/yum.repos.d/webmin.repo

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

# Función que se encarga de la instalación de WebMin
function install_webmin(){
    if [ -e $REPO_WEBMIN_FILE ];then
        rm $REPO_WEBMIN_FILE
    fi
    echo -e "[Webmin]\r\nname=Webmin Distribution Neutral\r\n#baseurl=http://download.webmin.com/download/yum\r\nmirrorlist=http://download.webmin.com/download/yum/mirrorlist\r\nenabled=1" > $REPO_WEBMIN_FILE
    cat $REPO_WEBMIN_FILE
    wget http://www.webmin.com/jcameron-key.asc -O /tmp/key.asc
    rpm --import /tmp/key.asc
    dnf -y install webmin
    systemctl daemon-reload
    systemctl enable webmin.service
    systemctl start webmin.service
}

# Función que se encarga de la configuración miníma de WebMin
function config_webmin(){
    echo "Configuración"
    #wget http://theme.winfuture.it/bwtheme.wbt.gz -O $TEMP_FILE
    #/usr/libexec/webmin/bootstrap
}

# Función que se encarga de comprobar si webmin está instalado con todos sus módulos
function check_instalation_webmin(){
    echo "La instalación de WebMin está:"
    systemctl daemon-reload
    systemctl status webmin.service
}

# Función para presentar el Menú
# Sin parámetros de entrada
function menu() {
    clear;
    echo
    echo "           ****************************************"
    echo "           *          Esto es el Menú             *"
    echo "           * 1.- Comprobar dependencias           *"
    echo "           * 2.- Instalación de WebMin            *"
    echo "           * 3.- Configuración de WebMin          *"
    echo "           * 4.- Instalación de modulos           *"
    echo "           * 5.- Comprobar instalación WebMin     *"
    echo "           *                                      *"
    echo "           * 0.- Salir                            *"
    echo "           ****************************************"
    echo
    read -p "           Elija una opción: " option
    case $option in
        0)
        exit;
        ;;
        1)
        check_depends;
        pause;
        menu;
        ;;
        2)
        install_webmin;
        pause;
        menu;
        ;;
        3)
        config_webmin;
        pause;
        menu;
        ;;
        4)

        pause;
        menu;
        ;;
        5)
        check_instalation_webmin;
        pause;
        menu;
        ;;
        *)
        echo "Opción no permitida";
        pause;
        menu;
        ;;
    esac
}
is_root;
menu;
