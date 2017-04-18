#!/bin/bash
# Titulo:       Instalación y configuración de Java de Oracle
# Fecha:        23/12/16
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción: Instalación de Java la versión de Oracle
# Opciones: Ninguna
# Uso: install-java.sh


# VARIABLES ESTATICAS DEL SCRIPT
DEPENDS_THIS_SCRIPT=(ifconfig nmap find git) # Dependencias necesarias

# VARIABLES GLOBALES DEL SCRIPT
TEST_IP=8.8.8.8
TEMP_FILE=/tmp/file.tmp
HTTP_DONWLOAD_JAVA=http://javadl.oracle.com/webapps/download/AutoDL?BundleId=218822_e9e7ea248e2c4826b92b3f075a80e441

# INCLUDES
path="$(dirname "$0")"
source "$path/functions-depends.sh"

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

# Función que se encarga de descargar y de instalar java sin configuración en el sistema
function install_java() {
    echo "Descargando Java..."
    wget $HTTP_DONWLOAD_JAVA -O $TEMP_FILE
    mv $TEMP_FILE java.rpm
    echo "Instalando Java..."
    dnf -y install java.rpm
    rm -f java.rpm
}

# Función para presentar el Menú
# Sin parámetros de entrada
function menu() {
    clear;
    echo
    echo "           ****************************************"
    echo "           *          Esto es el Menú             *"
    echo "           * 1.- Comprobar dependencias           *"
    echo "           * 2.- Instalar Java de Oracle          *"
    echo "           * 3.-                                  *"
    echo "           * 4.-                                  *"
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
        install_java;
        pause;
        menu;
        ;;
        3)

        pause;
        menu;
        ;;
        4)

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
