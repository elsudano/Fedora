#!/bin/bash
# Titulo:       Instalación y configuración PHP version 5.6
# Fecha:        23/12/16
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción: Instalación de PHP 5.6 junto con las extenciones necesarias para la versión de V·COMM
# Opciones: Ninguna
# Uso: install-php.sh


# VARIABLES ESTATICAS DEL SCRIPT
# poner todo esto como en los demas DEPENDS=(ifconfig nmap find git) # Dependencias necesarias
RPM_EPEL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RPM_WEBTATIC=https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

# VARIABLES GLOBALES DEL SCRIPT
TEST_IP=62.15.168.50
TEMP_FILE=/tmp/file.tmp

# INCLUDES
path="$(dirname "$0")"
source "$path/functions-depends.sh"

# Función privada que se encarga de hacer las instalaciones previas para la instalación de la versión PHP que corresponda
function pre_install_php(){
    wget $RPM_EPEL -O $TEMP_FILE
    mv $TEMP_FILE epel-release-latest-7.noarch.rpm
    dnf -y install epel-release-latest-7.noarch.rpm
    wget $RPM_WEBTATIC -O $TEMP_FILE
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
    # gd images
    dnf -y install php56w-gd.x86_64;
    systemctl restart httpd.service;
}

# Función que se encarga de instalar y configurar los modulos adicionales de PHP 7.0
function install_modules_php70() {
    # mbstring module
    dnf -y install php-mbstring.x86_64;
    # mcrypt module
    dnf -y install php-mcrypt.x86_64;
    # mssql mssqli PDOmssql module
    dnf -y install php-mssql.x86_64;
    # mysql mysqli PDOmysql module
    dnf -y install php-mysql.x86_64;
    # pgsql PDOpgsql module
    dnf -y install php-pgsql.x86_64;
    # xmlrpc module
    dnf -y install php-xmlrpc.x86_64;
    # xsl wddx shmop xmlwriter xmlreader xml modules
    dnf -y install php-xml.x86_64;
    # gd images
    dnf -y install php-gd.x86_64;
    systemctl restart httpd.service;
}

# Función que se encarga de modificar las variables concretas de PHP.ini para que funcione la aplicación
function config_phpini(){
    upload=$(request -m "¿Que tamaño maximo de fichero es el que se podrá subir al servidor? (ej: 2M sin unidades) ")
    if ! is_set $upload;then
        echo "Operación cancelada"
    else
        upload+="M"
        #Maximum allowed size for uploaded files.
        #http://php.net/upload-max-filesize
        sed -i "s/upload_max_filesize = .*$/upload_max_filesize = $upload/g" /etc/php.ini
    fi
    post=$(request -m "¿Que tamaño maximo de fichero es el que podrá enviar por el metodo post?: (ej: 8M sin unidades) ")
    if ! is_set $post;then
        echo "Operación cancelada"
    else
        post+="M"
        #Maximum size of POST data that PHP will accept.
        #Its value may be 0 to disable the limit. It is ignored if POST data reading
        #is disabled through enable_post_data_reading.
        #http://php.net/post-max-size
        sed -i "s/post_max_size = .*$/post_max_size = $post/g" /etc/php.ini
    fi
    memory=$(request -m "¿Cuál será el tamaño maximo de la ocupación de memoría?: (ej: 128M sin unidades) ")
    if ! is_set $memory;then
        echo "Operación cancelada"
    else
        memory+="M"
        #Maximum amount of memory a script may consume (128MB)
        #http://php.net/memory-limit
        sed -i "s/memory_limit = .*$/memory_limit = $memory/g" /etc/php.ini
    fi
    session_file=$(request -m "¿Cuál es la ruta relativa para las cookies? (ej: /)")
    if ! is_set $session_file;then
        echo "Operación cancelada"
    else
        #The path for which the cookie is valid.
        #http://php.net/session.cookie-path
        session_file=$(echo "$session_file" | sed 's/\//\\\//g')
        sed -i "s/session\.cookie_path = .*$/session\.cookie_path = $session_file/g" /etc/php.ini
    fi
    session_path=$(request -m "¿Cuál es la ruta absoluta donde se almacenarán los ficheros de session? (ej: /tmp)")
    if ! is_set $session_path;then
        echo "Operación cancelada"
    else
        #http://php.net/session.save-path
        session_path=$(echo "$session_path" | sed 's/\//\\\//g')
        sed -i "s/session\.save_path = .*$/session\.save_path = $session_path/g" /etc/php.ini
    fi
    echo "Los valores asignados a las variables son los siguientes: "
    cat /etc/php.ini | grep "upload_max_filesize = "
    cat /etc/php.ini | grep "post_max_size = "
    cat /etc/php.ini | grep "memory_limit = "
    cat /etc/php.ini | grep "session.cookie_path = "
    cat /etc/php.ini | grep "session.save_path = "
    pause -m
}

# Función que se encarga realizar la instalación mínima de PHP ver. 7.0
function create_phpinfo(){
    echo "Crearemos el fichero de test.php y mostraremos que es lo que contiene"
    echo "¿Cuál es el usuario que se encarga de gestionar el servidor web? "
    sel_user user
    if ! is_set $user;then
        echo "El usuario no puede ser vacio"
    else
        homedir=$( getent passwd "$user" | cut -d: -f6)
        echo -e "<?php\r\nphpinfo();\r\n?>\r\nSi solo vez este texto es que te falta instalar PHP" > $homedir/test.php
        echo
        echo -e "Resultado:\r\n"
        curl http://localhost/test.php;
    fi
    echo
    pause -m "Pulse ENTER para continuar";
    read -p "Desea eliminar el fichero de prueba: $homedir/test.php (S/N) " opt
    if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
        rm -f $homedir/test.php
    fi
}

# Función que se encarga de borrar el fichero de test.php
function delete_phpinfo(){
    echo "¿Cuál es el usuario que se encarga de gestionar el servidor web? "
    sel_user user
    if is_set $user;then
        homedir=$( getent passwd "$user" | cut -d: -f6)
        read -p "Desea eliminar el fichero de prueba: $homedir/test.php (S/N) " opt
        if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
            rm -f $homedir/test.php
        fi
    else
        echo "El usuario no puede ser vacio";
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
    echo "           * 6.- Configurar PHP.ini               *"
    echo "           * 7.- Crear fichero PHPINFO            *"
    echo "           * 8.- Eliminar fichero PHPINFO         *"
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
        config_phpini;
        pause;
        menu;
        ;;
        7)
        create_phpinfo;
        pause;
        menu;
        ;;
        8)
        delete_phpinfo;
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
