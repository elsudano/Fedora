#!/bin/bash
# Titulo:       Instalación y configuración de MySQL, versión de Oracle
# Fecha:        23/12/16
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción: Instalación de MySQL versión privada, hay que tener cuidado por que para poder actualzar el servidor de base hay que descargar
# por completo los instaladores desde la página web de oracle
# Opciones: Ninguna
# Uso: install-java.sh


# VARIABLES ESTATICAS
DEPENDS=(dnf rpm find git) # Dependencias necesarias
DIRS=(/usr/bin /usr/sbin /bin /var/lib/mysql/ /var/run/mysqld/ /usr/local/mysql/data/) # Directorios de busqueda
MASKS_CIDR=(32 31 30 29 28 27 26 25 24 23 22)
MASKS_DEC=(255.255.255.255 255.255.255.254 255.255.255.252 255.255.255.248 255.255.255.240 255.255.255.224 255.255.255.192 255.255.255.128 255.255.255.0 255.255.254.0 255.255.252.0)

# VARIABLES GLOBALES
TEST_IP=62.15.168.50
TEMP_FILE=/tmp/file.tmp
ADMIN_USER_DB=admindb
ADMIN_USER_PASS=password
MYSQL_SERVICE_FILE=/usr/lib/systemd/system/mysqld.service

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

function create_user() {
    echo "Indique el usuario que desea crear"
    pause --with-msg;
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
    sed -i "s/ExecStart=.*$/ExecStart=\/usr\/sbin\/mysqld --daemonize --pid-file=$PIDFile \$MYSQLD_OPTS/g" $MYSQL_SERVICE_FILE
    systemctl daemon-reload
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
    if [ -n $ADMIN_USER_PASS ];then
        ADMIN_USER_PASS=password
    fi
    echo "Detenemos el servidor de MySQL..."
    systemctl stop mysqld.service
    echo "Buscamos el fichero .pid...."
    local hit=0
    for dir in ${DIRS[@]}
    do
        if [ -x "$dir/mysqld.pid" ]; then
            echo "Fichero encontrado..."
            rm -f $dir/mysqld.pid
            echo "Fichero eliminado..."
            break;
        fi
    done
    if [ $hit == 0 ]; then
        echo "No se encuentra el fichero .PID"
    fi
    echo "Creamos el fichero para cambiar la contraseña"
    echo -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$ADMIN_USER_PASS';" > $TEMP_FILE
    echo "Asignamos el fichero al inicio de MySQL..."
    systemctl set-environment MYSQLD_OPTS="--init-file=$TEMP_FILE"
    echo "Arrancamos MySQL..."
    systemctl start mysqld.service
    # echo "Quitamos el fichero del inicio..."
    # systemctl unset-environment MYSQLD_OPTS
    # echo "Reiniciamos MySQL..."
    # systemctl restart mysqld.service
    # echo "Eliminamos fichero temporal..."
    # rm -f $TEMP_FILE
}

# Función que se encarga de intalar el servidor de MySQL de Oracle
function create_user_admin_db(){
    echo "Crearemos un usuario de administración para MySQL"
    read -p "Indique el usuario: (default:$ADMIN_USER_DB) " ADMIN_USER_DB
    if [ -n $ADMIN_USER_DB ];then
        ADMIN_USER_DB=admindb
    fi
    read -p "Indique la contraseña del usuario: (default:$ADMIN_USER_PASS) " ADMIN_USER_PASS
    if [ -n $ADMIN_USER_PASS ];then
        ADMIN_USER_PASS=password
    fi
    read -p "Indique la contraseña de root: " pass
    if [ -n $pass ];then
        echo "La contraseña de root no puede ser vacía"
    else
        mysql -u root -p $pass -h localhost -e "CREATE USER '$ADMIN_USER_DB'@'localhost' IDENTIFIED BY '$ADMIN_USER_PASS';"
        mysql -u root -p $pass -h localhost -e "GRANT ALL PRIVILEGES ON * . * TO '$ADMIN_USER_DB'@'localhost';"
    fi
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
    echo "           * 7.- Habilitar/Deshabilitar MySQL     *"
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
        start_stop_mysql;
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
