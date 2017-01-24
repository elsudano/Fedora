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
PATH_DATA_VCOMM=/datawww/datavcomm
APACHE_USER=gestapa
APACHE_GROUP=datawww

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

# Función que se encarga de crear los usuarios y los grupos para el correcto funcionamiento
function create_user_and_group(){
    echo "Crearemos un usuario para apache"
    read -p "Indique el usuario: (default:$APACHE_USER) " APACHE_USER
    read -p "Cuál es el nombre del usuario completo: " complete_name_user
    read -p "Indique el grupo al que pertenece: (default:$APACHE_GROUP) " APACHE_GROUP
    echo "El directorio donde se alojan las webs es: $PATH_DATA_WEB"
    read -p "¿Es correcto? (Y/N): " opt
    if [[ $opt == "n" ]] || [[ $opt == "n" ]];then
        read -p "Indique la ruta donde se almacenarán las webs: " PATH_DATA_WEB
    fi
    groupadd -f $APACHE_GROUP
    useradd -M -d $PATH_DATA_WEB -c "$complete_name_user" -g $APACHE_GROUP $APACHE_USER
    chown -R $APACHE_USER:$APACHE_GROUP $PATH_DATA_WEB
}

# Función que se encarga de crear los directorios para los datos y el directorio root web para apache
function create_data_root_path(){
    if [ -e $PATH_DATA_WEB ] && [ -d $PATH_DATA_WEB ];then
        read -p "Desea utilizar el directorio $PATH_DATA_WEB como root web? (Y/N): " opt
        if [ $opt == "n" ] || [ $opt == "N" ];then
            read -p "Indique el directorio root web:" PATH_DATA_WEB
            mkdir $PATH_DATA_WEB
            echo "Se ha creado el directorio $PATH_DATA_WEB para alojar la instalación WEB"
        fi
    else
        read -p "Indique el directorio root web: (default:$PATH_DATA_WEB) " PATH_DATA_WEB
        if [ -n $PATH_DATA_WEB ];then
            PATH_DATA_WEB="/datawww/html"
        fi
        echo "dir: $PATH_DATA_WEB"
        mkdir $PATH_DATA_WEB
        echo "Se ha creado el directorio $PATH_DATA_WEB para alojar la instalación WEB"
    fi
    # Con esto nos aseguramos que el directorio de datos esta en el mismo directorio que el root
    if [ ! -e $PATH_DATA_WEB/../datavcomm ];then
        echo "Se creará el directorio 'datavcomm' al mismo nivel que $PATH_DATA_WEB para alojar datos del software"
        cd $PATH_DATA_WEB
        cd ..
        mkdir ./datavcomm
    fi
}

# Función que se encarga realizar la instalación mínima de Apache
function install_apache(){
    echo "Comienza la instalación de Apache"
    dnf -y install httpd.x86_64
}

# Función que se encarga realizar la instalación de los módulos necesarios para V·COMM
function install_apache_modules(){
    echo "Instalación de SSL module"
    dnf -y install mod_ssl.x86_64
}

# Función para presentar el Menú
# Sin parámetros de entrada
function menu() {
    clear;
    echo
    echo "           ****************************************"
    echo "           *          Esto es el Menú             *"
    echo "           * 1.- Comprobar Dependencias           *"
    echo "           * 2.- Crear Usuario y Grupo Apache     *"
    echo "           * 3-  Crear dir. Root y Data           *"
    echo "           * 4-  Instalar Apache                  *"
    echo "           * 5.- Instalar módulos de Apache       *"
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
        create_user_and_group;
        pause;
        menu;
        ;;
        3)
        create_data_root_path;
        pause;
        menu;
        ;;
        4)
        install_apache;
        pause;
        menu;
        ;;
        5)
        install_apache_modules;
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
