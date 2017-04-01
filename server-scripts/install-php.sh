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
RPM_FUSION_FREE=https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-25.noarch.rpm
RPM_FUSION_NOFREE=https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-25.noarch.rpm
RPM_REMI=http://rpms.famillecollet.com/fedora/remi-release-25.rpm
DIR_OVERRIDE=/etc/systemd/system/httpd.service.d
FILE_OVERRIDE=/etc/systemd/system/httpd.service.d/override.conf

# VARIABLES GLOBALES DEL SCRIPT
TEST_IP=62.15.168.50
TEMP_FILE=/tmp/file.tmp
REPO=0

# INCLUDES
path="$(dirname "$0")"
source "$path/functions-depends.sh"

# Función privada que se encarga de hacer las instalaciones previas para la instalación de la versión PHP que corresponda
function pre_install_php(){
    wget $RPM_EPEL -O $TEMP_FILE
    mv $TEMP_FILE epel-release-latest-7.noarch.rpm
    dnf -y install epel-release-latest-7.noarch.rpm
    rm -f epel-release-latest-7.noarch.rpm
}

# Función que se encarga de intalar el repositorio de PHP que se necesita
function repo_install(){
    pre_install_php;
    #Seleccionar repositorio
    REPO=$(request -m "¿Que repositorio quiere usar? 1-WebStatic / 2-REMI " -v 2)
    if [[ $REPO == "1" ]]; then
      wget $RPM_WEBTATIC -O $TEMP_FILE
      mv $TEMP_FILE webtatic-release.rpm
      dnf -y install webtatic-release.rpm
      rm -f webtatic-release.rpm
    elif [[ $REPO == "2" ]]; then
      wget $RPM_FUSION_FREE -O $TEMP_FILE
      mv $TEMP_FILE rpmfusion-free-release-25.noarch.rpm
      wget $RPM_FUSION_NOFREE -O $TEMP_FILE
      mv $TEMP_FILE rpmfusion-nonfree-release-25.noarch.rpm
      wget $RPM_REMI -O $TEMP_FILE
      mv $TEMP_FILE remi-release-25.rpm
      dnf -y install rpmfusion-free-release-25.noarch.rpm rpmfusion-nonfree-release-25.noarch.rpm remi-release-25.rpm
      rm -f rpmfusion-free-release-25.noarch.rpm rpmfusion-nonfree-release-25.noarch.rpm remi-release-25.rpm
      sed -i "s/enabled=0$/enabled=1/g" /etc/yum.repos.d/remi.repo
    else
      echo "opción no valida"
    fi
}

# Función que se encarga realizar la instalación mínima de PHP ver. 5.6
function install_php56(){
    REPO=$(request -m "¿Que repositorio quiere usar? 1-WebStatic / 2-REMI " -v 2)
    if [[ $REPO == "1" ]]; then
      echo "Comienza la instalación de PHP 5.6 de WebStatic"
      dnf -y install php56w.x86_64;
      systemctl restart httpd.service;
    elif [[ $REPO == "2" ]]; then
      echo "Comienza la instalación de PHP 5.6 de REMI"
      dnf -y install php56-php.x86_64;
      systemctl restart httpd.service;
    else
      echo "opción no valida"
    fi
}

# Función que se encarga realizar la instalación mínima de PHP ver. 7.0
function install_php70(){
  REPO=$(request -m "¿Que repositorio quiere usar? 1-WebStatic / 2-REMI / 3-Fedora" -v 3)
  if [[ $REPO == "1" ]]; then
    echo "Comienza la instalación de PHP 5.6 de WebStatic"
    dnf -y install php70w.x86_64;
    systemctl restart httpd.service;
  elif [[ $REPO == "2" ]]; then
    echo "Comienza la instalación de PHP 5.6 de REMI"
    dnf -y install php70-php.x86_64;
    systemctl restart httpd.service;
  elif [[ $REPO == "3" ]]; then
    echo "Comienza la instalación de PHP 7.0 desde Fedora"
    dnf -y install php.x86_64;
    systemctl restart httpd.service;
  else
    echo "opción no valida"
  fi
}

# Función que se encarga de instalar y configurar los modulos adicionales de PHP 5.6
function install_modules_php56() {
    REPO=$(request -m "¿Que repositorio quiere usar? 1-WebStatic / 2-REMI " -v 2)
    if [[ $REPO == "1" ]]; then
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
    elif [[ $REPO == "2" ]]; then
      # mbstring module
      dnf -y install php56-php-mbstring.x86_64;
      # mcrypt module
      dnf -y install php56-php-mcrypt.x86_64;
      # mssql mssqli PDOmssql module
      dnf -y install php56-php-mssql.x86_64;
      # mysql mysqli PDOmysql module
      dnf -y install php56-php-mysqlnd.x86_64;
      # pgsql PDOpgsql module
      dnf -y install php56-php-pgsql.x86_64;
      # xmlrpc module
      dnf -y install php56-php-xmlrpc.x86_64;
      # xsl wddx shmop xmlwriter xmlreader xml modules
      dnf -y install php56-php-xml.x86_64;
      # gd images
      dnf -y install php56-php-gd.x86_64;
      systemctl restart httpd.service;
    else
      echo "opción no valida"
    fi
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

function install_oracle() {
  # Descargar los RPM desde el repositorio de update
  wget https://update.vcomm.es/oracle_installs/oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm -O $TEMP_FILE
  mv $TEMP_FILE oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm
  dnf -y install oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm
  rm -f oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm
  # oci8 conexión oracle database
  dnf -y install php56-php-oci8.x86_64
  # odbc para php
  dnf -y install php56-php-odbc.x86_64
  if [ -e $FILE_OVERRIDE ];then
      echo -e "[Service]" > $FILE_OVERRIDE
      echo -e "Environment=LD_LIBRARY_PATH=/usr/lib/oracle/12.2/client64/lib" >> $FILE_OVERRIDE
      echo -e "Environment=LD_LIBRARY_PATH64=/usr/lib/oracle/12.2/client64/lib" >> $FILE_OVERRIDE
  else
      mkdir $DIR_OVERRIDE
      touch $FILE_OVERRIDE
      echo -e "[Service]" > $FILE_OVERRIDE
      echo -e "Environment=LD_LIBRARY_PATH=/usr/lib/oracle/12.2/client64/lib" >> $FILE_OVERRIDE
      echo -e "Environment=LD_LIBRARY_PATH64=/usr/lib/oracle/12.2/client64/lib" >> $FILE_OVERRIDE
  fi
  systemctl daemon-reload;
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
    sel_group group
    if ! is_set $user; then
        echo "El usuario no puede ser vacio"
    elif ! is_set $group; then
        echo "El grupo no puede ser vacio"
    else
        homedir=$( getent passwd "$user" | cut -d: -f6)
        echo -e "<?php\r\nphpinfo();\r\n?>\r\nSi solo vez este texto es que te falta instalar PHP" > $homedir/test.php
        echo
        chown $user:$group $homedir/test.php
        echo -e "Resultado:\r\n"
        curl http://localhost/test.php;
    fi
    echo
    pause -m "Pulse ENTER para continuar";
    read -p "Desea eliminar el fichero de prueba: $homedir/test.php (S/N) " opt
    [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]] && rm -f $homedir/test.php
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
    echo "           * 2.- Instalar repositorio de PHP      *"
    echo "           * 3.- Instalar PHP 5.6                 *"
    echo "           * 4.- Instalar PHP 7.0                 *"
    echo "           * 5.- Instalar modulos de PHP 5.6      *"
    echo "           * 6.- Instalar modulos de PHP 7.0      *"
    echo "           * 7.- Instalar Oracle OCI8             *"
    echo "           * 8.- Configurar PHP.ini               *"
    echo "           * 9.- Crear fichero PHPINFO            *"
    echo "           * 10.- Eliminar fichero PHPINFO        *"
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
        repo_install;
        pause;
        menu;
        ;;
        3)
        install_php56;
        pause;
        menu;
        ;;
        4)
        install_php70;
        pause;
        menu;
        ;;
        5)
        install_modules_php56;
        pause;
        menu;
        ;;
        6)
        install_modules_php70;
        pause;
        menu;
        ;;
        7)
        install_oracle;
        pause -m;
        menu;
        ;;
        8)
        config_phpini;
        pause;
        menu;
        ;;
        9)
        create_phpinfo;
        pause;
        menu;
        ;;
        10)
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
