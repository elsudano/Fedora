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

# Función privada que se encarga de hacer las instalaciones previas para la instalación de la versión PHP que corresponda
function pre_install_php(){
    wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -O $TEMP_FILE
    mv $TEMP_FILE epel-release-latest-7.noarch.rpm.rpm
    dnf -y install epel-release-latest-7.noarch.rpm.rpm
    wget https://mirror.webtatic.com/yum/el7/webtatic-release.rpm -O $TEMP_FILE
    mv $TEMP_FILE webtatic-release.rpm
    dnf -y install webtatic-release.rpm
    rm -f epel-release-latest-7.noarch.rpm
    rm -f webtatic-release.rpm
}
# Función que se encarga realizar la instalación mínima de PHP ver. 5.6
function install_php56(){
    echo "Comienza la instalación de PHP 5.6"
    pre_install_php;
    dnf -y install php56w.x86_64;
    systemctl restart httpd.service;
}

# Función que se encarga realizar la instalación mínima de PHP ver. 7.0
function install_php70(){
    echo "Comienza la instalación de PHP 7.0"
    pre_install_php;
    dnf -y install php.x86_64;
    systemctl restart httpd.service;
}

# Función que se encarga de instalar y configurar los modulos adicionales de PHP 5.6
function install_modules_php56() {
    # mbstring module
    dnf -y install php56w-mbstring.x86_64;
    # mcrypt module
    dnf -y install php56w-mcrypt.x86_64;
    # mssql mssqli PDOmssql module
    dnf -y install php56w-mssql.x86_64;
    # mysql mysqli PDOmysql module
    dnf -y install php56w-mysql.x86_64;
    # pgsql PDOpgsql module
    dnf -y install php56w-pgsql.x86_64;
    # xmlrpc module
    dnf -y install php56w-xmlrpc.x86_64;
    # xsl wddx shmop xmlwriter xmlreader xml modules
    dnf -y install php56w-xml.x86_64;
    systemctl restart httpd.service;
}

# Función que se encarga de instalar y configurar los modulos adicionales de PHP 7.0
function install_modules_php70() {

}

# Función que se encarga realizar la instalación mínima de PHP ver. 7.0
function create_phpinfo(){
    echo "Crearemos el fichero de test.php y mostraremos que es lo que contiene"
    read -p "¿Cuál es el usuario que se encarga de gestionar el servidor web? " user
    if [ -z $user ];then
        echo "El usuario no puede ser vacio"
        clear;
        create_phpinfo;
    else
        homedir=$( getent passwd "$user" | cut -d: -f6)
        echo -e "<?php\r\nphpinfo();" > $homedir/test.php
        echo
        echo -e "Resultado:\r\n"
        curl http://localhost/test.php;
    fi
    echo
    pause --with-msg "Pulse ENTER para continuar";
    clear;
    read -p "Desea eliminar el fichero de prueba: $homedir/test.php (S/N) " opt
    if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
        rm -f $homedir/test.php
    fi
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
    echo "           * 4.- Instalar modulos de PHP 5.6      *"
    echo "           * 5.- Instalar modulos de PHP 7.0      *"
    echo "           * 6.- Crear fichero PHPINFO            *"
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
        install_modules_php56;
        pause;
        menu;
        ;;
        5)
        install_modules_php70;
        pause;
        menu;
        ;;
        6)
        create_phpinfo;
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
