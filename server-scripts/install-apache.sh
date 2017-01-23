#!/bin/bash
# Titulo:       Instalación y configuración de Apache
# Fecha:        23/12/16
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción: Instalación de Apache y configuración de módulos
# Opciones: Ninguna
# Uso: install-apache.sh


# VARIABLES ESTATICAS
DEPENDS=(ifconfig nmap find git) # Dependencias necesarias
DIRS=(/usr/bin /usr/sbin /bin) # Directorios de busqueda
MASKS_CIDR=(32 31 30 29 28 27 26 25 24 23 22)
MASKS_DEC=(255.255.255.255 255.255.255.254 255.255.255.252 255.255.255.248 255.255.255.240 255.255.255.224 255.255.255.192 255.255.255.128 255.255.255.0 255.255.254.0 255.255.252.0)

# VARIABLES GLOBALES
TEST_IP=62.15.168.50
TEMP_FILE=/tmp/file.tmp
PATH_DATA_WEB=/datawww/html

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

# Función que se encarga realizar la instalación mínima de Apache
function install_apache(){
    echo "Comienza la instalación de Apache"
    dnf -y install httpd.x86_64
    if [ ! -e -d $PATH_DATA_WEB ];then
        echo "Se ha creado el directorio $PATH_DATA_WEB para alojar la instalación WEB"
        mkdir $PATH_DATA_WEB
    fi
}

# Función que se encarga realizar la instalación de los módulos necesarios para V·COMM
function install_apache_modules(){
    echo "Instalación de SSL module"
    dnf -y install mod_ssl.x86_64
}

# Función que se encarga de crear los usuarios y los grupos para el correcto funcionamiento
function create_user_and_group(){
    echo "Crearemos un usuario para apache"
    read -p "Indique el usuario: " name_user
    read -p "Cuál es el nombre del usuario completo: " complete_name_user
    read -p "Indique el grupo al que pertenece: " name_group
    echo "El directorio donde se alojan las webs es: $PATH_DATA_WEB"
    read -p "¿Es correcto? (Y/N): " opt
    if [[ $opt == "n" ]] || [[ $opt == "n" ]];then
        read -p "Indique la ruta donde se almacenarán las webs: " PATH_DATA_WEB
    fi
    groupadd -f $name_group
    useradd -M -d $PATH_DATA_WEB -c "$complete_name_user" -g $name_group $name_user
}

# Función para presentar el Menú
# Sin parámetros de entrada
function menu() {
    clear;
    echo
    echo "           ****************************************"
    echo "           *          Esto es el Menú             *"
    echo "           * 1.- Comprobar Dependencias           *"
    echo "           * 2.- Instalar Apache                  *"
    echo "           * 3.- Instalar módulos de Apache       *"
    echo "           * 4.- Crear Usuario y Grupo Apache     *"
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
        install_apache;
        pause;
        menu;
        ;;
        3)
        install_apache_modules;
        pause;
        menu;
        ;;
        4)
        create_user_and_group;
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
