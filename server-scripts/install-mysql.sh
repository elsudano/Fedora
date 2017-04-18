#!/bin/bash
# Titulo:       Instalación y configuración de MySQL, versión de Oracle
# Fecha:        23/12/16
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción: Instalación de MySQL versión privada, hay que tener cuidado por que para poder actualzar el servidor de base hay que descargar
# por completo los instaladores desde la página web de oracle
# Opciones: Ninguna
# Uso: install-java.sh


# VARIABLES ESTATICAS DEL SCRIPT
# poner esto como todos los demas DEPENDS=(dnf rpm find git) # Dependencias necesarias
# añadir este valor tambien para poder como parametro en la funcion de check_depends
  # DIRS=(/usr/bin /usr/sbin /bin /var/lib/mysql/ /var/run/mysqld/ /usr/local/mysql/data/) # Directorios de busqueda

# VARIABLES GLOBALES DEL SCRIPT
TEST_IP=8.8.8.8
TEMP_FILE=/tmp/file.tmp
ADMIN_USER_DB=admindb
ADMIN_USER_PASS=password
MYSQL_SERVICE_FILE=/usr/lib/systemd/system/mysqld.service
NAME_DB=VCOMM

# INCLUDES
path="$(dirname "$0")"
source "$path/functions-depends.sh"

# Función que se encarga de intalar el repositorio de MySQL de Oracle
function repo_install(){
    # Fedora 25 MySQL 5.7
    wget https://dev.mysql.com/get/mysql57-community-release-fc25-9.noarch.rpm -O $TEMP_FILE
    # EPL7 MySQL 5.7
    # wget https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm -O $TEMP_FILE
    mv $TEMP_FILE mysql-repo.rpm
    dnf -y install mysql-repo.rpm
    rm -f mysql-repo.rpm
}

# Función que se encarga de intalar el servidor de MySQL de Oracle
function install_server(){
    dnf -y install community-mysql-server.x86_64
    PIDFile=$(cat $MYSQL_SERVICE_FILE | awk -F'=' '/PIDFile=/{print $2}')
    PIDFile=$(echo "$PIDFile" | sed 's/\//\\\//g')
    systemctl stop mysqld.service
    sed -i "s/ExecStart=.*$/ExecStart=\/usr\/libexec\/mysqld --daemonize --basedir=\/usr --pid-file=$PIDFile \$MYSQLD_OPTS/g" $MYSQL_SERVICE_FILE
    systemctl unset-environment MYSQLD_OPTS
    systemctl daemon-reload
    systemctl start mysqld.service
}

# Función que se encarga de poner la primera contraseña al usuario root
function put_pass_root(){
    read -p "Indique la nueva contraseña de root: (default:$ADMIN_USER_PASS) " ADMIN_USER_PASS
    if [ -n $ADMIN_USER_PASS ];then
        ADMIN_USER_PASS=password
    fi
    systemctl start mysqld.service
    mysql -u root -h localhost -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$ADMIN_USER_PASS';"
    systemctl restart mysqld.service
    echo "Contraseña aplicacda...."
}

# Función que se encarga cambiar la contraseña del usuario root de MySQL 5.7 en adelante
function change_pass_root(){
    read -p "Indique la nueva contraseña de root: (default:$ADMIN_USER_PASS) " ADMIN_USER_PASS
    if [ -z $ADMIN_USER_PASS ];then
        ADMIN_USER_PASS=password
    fi
    echo "Detenemos el servidor de MySQL..."
    systemctl stop mysqld.service
    echo "Asignamos valor a la variable de debug..."
    systemctl set-environment MYSQLD_OPTS=" --user=mysql --skip-grant-tables"
    echo "Cargamos de nuevo los servicios"
    systemctl daemon-reload
    echo "Arrancamos MySQL..."
    systemctl start mysqld.service
    pause;
    systemctl status mysqld.service
    echo -e " \r\n"
    echo "A continuación copia la siguiente sentencia y ejecutala en el cliete de mysql"
    echo -e " \r\n"
    echo "UPDATE mysql.user"
    echo "SET authentication_string = PASSWORD('$ADMIN_USER_PASS'), password_expired = 'N'"
    echo "WHERE User = 'root' AND Host = 'localhost';"
    echo "FLUSH PRIVILEGES;"
    echo "QUIT;"
    echo -e " \r\n"
    mysql
    echo "Quitamos la variable de debug..."
    systemctl unset-environment MYSQLD_OPTS
    echo "Reiniciamos MySQL..."
    systemctl restart mysqld.service
    pause;
    systemctl status mysqld.service
}

# Función que se encarga crear el usuario de administración de la base de datos
function create_user_admin_db(){
    echo "Crearemos un usuario de administración para MySQL"
    read -p "Indique el usuario: (default:$ADMIN_USER_DB) " ADMIN_USER_DB
    if [ -z $ADMIN_USER_DB ];then
        ADMIN_USER_DB=admindb
    fi
    read -p "Indique la contraseña del usuario: (default:$ADMIN_USER_PASS) " ADMIN_USER_PASS
    if [ -z $ADMIN_USER_PASS ];then
        ADMIN_USER_PASS=password
    fi
    echo "Indique la contraseña de root: "
    mysql -u root -p -h localhost -e "CREATE USER '$ADMIN_USER_DB'@'localhost' IDENTIFIED BY '$ADMIN_USER_PASS';"
    mysql -u root -p -h localhost -e "GRANT ALL ON *.* TO '$ADMIN_USER_DB'@'localhost' WITH GRANT OPTION;"
    mysql -u root -p -h localhost -e "SELECT host, user FROM mysql.user;"
}

# Función que se encarga de crear la base de datos para V·COMM
function create_db(){
    read -p "Nombre de la Base de datos: (default:$NAME_DB) " NAME_DB
    if [ -n $NAME_DB ];then
        NAME_DB=VCOMM
    fi
    read -p "Usuario administrador: (default:$ADMIN_USER_DB) " ADMIN_USER_DB
    if [ -n $ADMIN_USER_DB ];then
        ADMIN_USER_DB=admindb
    fi
    echo "Indique la contraseña de $ADMIN_USER_DB: "
    mysql -u $ADMIN_USER_DB -p -h localhost -e "CREATE DATABASE $NAME_DB;"

}

# Función para arrancar y detener el servicio de MySQL
function start_stop_mysql(){
    read -p "Elija la opción a realizar\n([E]stado/[I]niciar/[D]etener/[R]einiciar/[H]abilitar/Desa[b]ilitar/[C]ancelar): " opt
    if [[ $opt == "e" ]] || [[ $opt == "E" ]];then
        systemctl status mysqld.service
    elif [[ $opt == "i" ]] || [[ $opt == "I" ]];then
        systemctl start mysqld.service
    elif [[ $opt == "d" ]] || [[ $opt == "D" ]];then
        systemctl stop mysqld.service
    elif [[ $opt == "r" ]] || [[ $opt == "R" ]]; then
        systemctl restart mysqld.service
    elif [[ $opt == "h" ]] || [[ $opt == "H" ]];then
        systemctl enable mysqld.service
    elif [[ $opt == "b" ]] || [[ $opt == "B" ]];then
        systemctl disable mysqld.service
    elif [[ $opt == "c" ]] || [[ $opt == "C" ]];then
        echo "Cancelado";
    else
        clear;
        start_stop_mysql;
    fi
}

# Función para presentar el Menú
# Sin parámetros de entrada
function menu() {
    clear;
    echo
    echo "           ****************************************"
    echo "           *          Esto es el Menú             *"
    echo "           * 1.- Comprobar dependencias           *"
    echo "           * 2.- Instalar el repositorio          *"
    echo "           * 3.- Instalar servidor MySQL          *"
    echo "           * 4.- Poner contraseña a Root          *"
    echo "           * 5.- Cambiar la Pass de Root          *"
    echo "           * 6.- Crear un usuario Admin. BD       *"
    echo "           * 7.- Crear Esquema de BD V·COMM       *"
    echo "           * 8.- Habilitar/Deshabilitar MySQL     *"
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
        repo_install;
        pause --with-msg;
        menu;
        ;;
        3)
        install_server;
        pause --with-msg;
        menu;
        ;;
        4)
        put_pass_root;
        pause;
        menu;
        ;;
        5)
        change_pass_root;
        pause --with-msg;
        menu;
        ;;
        6)
        create_user_admin_db;
        pause;
        menu;
        ;;
        7)
        create_db;
        pause;
        menu;
        ;;
        8)
        start_stop_mysql;
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
