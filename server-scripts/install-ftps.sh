#!/bin/bash
# Titulo:       Instalación y configuración del servidor SSH
# Fecha:        28/03/17
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción: Instalación y configuración de un servidor de FTP de manera segura
# Opciones: Ninguna
# Uso: install-ftps.sh


# VARIABLES ESTATICAS DEL SCRIPT
# poner todo esto como en los demas DEPENDS=(ifconfig nmap find git) # Dependencias necesarias

# VARIABLES GLOBALES DEL SCRIPT
TEST_IP=62.15.168.50
TEMP_FILE=/tmp/file.tmp

# INCLUDES
path="$(dirname "$0")"
source "$path/functions-depends.sh"

# Función para presentar el Menú
# Sin parámetros de entrada
function menu() {
    clear;
    echo
    echo "           ****************************************"
    echo "           *          Esto es el Menú             *"
    echo "           * 1.- Comprobar Dependencias           *"
    echo "           * 2.- Instalar vFTPd                   *"
    echo "           * 3.-                                  *"
    echo "           * 4.- Configurar vFTPd                 *"
    echo "           *                                      *"
    echo "           * 0.- Salir                            *"
    echo "           ****************************************"
    echo
    option=$(request -m "Elija una opción: " -v 0)
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
