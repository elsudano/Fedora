#!/bin/bash
# Titulo:       Instalación y configuración PHP version 5.6
# Fecha:        23/12/16
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción: Instalación de PHP 5.6 junto con las extenciones necesarias para la versión de V·COMM
# Opciones: Ninguna
# Uso: install-php.sh


# VARIABLES ESTATICAS
DEPENDS=(ifconfig nmap find git) # Dependencias necesarias
DIRS=(/usr/bin /usr/sbin /bin) # Directorios de busqueda
MASKS_CIDR=(32 31 30 29 28 27 26 25 24 23 22)
MASKS_DEC=(255.255.255.255 255.255.255.254 255.255.255.252 255.255.255.248 255.255.255.240 255.255.255.224 255.255.255.192 255.255.255.128 255.255.255.0 255.255.254.0 255.255.252.0)

# VARIABLES GLOBALES
TEST_IP=62.15.168.50
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

# Función que se encarga realizar la instalación mínima de PHP ver. 5.6
function install_php56(){
    echo "Comienza la instalación de PHP 5.6"
    dnf -y install php.x86_64
}

# Función que se encarga realizar la instalación mínima de PHP ver. 7.0
function install_php70(){
    echo "Comienza la instalación de PHP 7.0"
    #dnf -y install php.x86_64
}

# Función para presentar el Menú
# Sin parámetros de entrada
function menu() {
    clear;
    echo
    echo "           ****************************************"
    echo "           *          Esto es el Menú             *"
    echo "           * 1.- Comprobar Dependencias           *"
    echo "           * 2.- Instalar PHP 5.6                 *"
    echo "           * 3.- Instalar PHP 7.0                 *"
    echo "           * 4.-                                  *"
    echo "           * 5.-                                  *"
    echo "           * 6.-                                  *"
    echo "           * 7.-                                  *"
    echo "           * 8.-                                  *"
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
        install_php56;
        pause;
        menu;
        ;;
        3)
        install_php70;
        pause;
        menu;
        ;;
        4)

        pause;
        menu;
        ;;
        5)

        pause;
        menu;
        ;;
        6)

        pause;
        menu;
        ;;
        7)

        pause;
        menu;
        ;;
        8)

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
