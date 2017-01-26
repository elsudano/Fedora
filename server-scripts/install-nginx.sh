#!/bin/bash
# Titulo:       Instalación y configuración de NGINX
# Fecha:        23/12/16
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción: Instalación de servidor de servidor HTTP como balanceador de carga
# Opciones: Ninguna
# Uso: install-nginx.sh


# VARIABLES ESTATICAS
DEPENDS=(ifconfig nmap find git nginx) # Dependencias necesarias
DIRS=(/usr/bin /usr/sbin /bin) # Directorios de busqueda
MASKS_CIDR=(32 31 30 29 28 27 26 25 24 23 22)
MASKS_DEC=(255.255.255.255 255.255.255.254 255.255.255.252 255.255.255.248 255.255.255.240 255.255.255.224 255.255.255.192 255.255.255.128 255.255.255.0 255.255.254.0 255.255.252.0)

# VARIABLES GLOBALES
TEST_IP=62.15.168.50
TEMP_FILE=/tmp/file.tmp
CONF_FILE_NGINX=/etc/nginx/nginx.conf
SERVER_IP=127.0.0.1

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

# Función para la instalación básica de NGINX
function install_nginx(){
    echo "Instalando NGINX..."
    dnf -y install nginx.x86_64
}

# Función para configurar NGINX
function config_nginx(){
    echo "Comenzamos a configurar Nginx"
    CONF_FILE_NGINX=$(buscar nginx.conf)
    if [ -n $CONF_FILE_NGINX ];then
        CONF_FILE_NGINX=/etc/nginx/nginx.conf
    fi
    if [ -e $CONF_FILE_NGINX ];then
        cp --backup=numbered $CONF_FILE_NGINX $CONF_FILE_NGINX.bak
        rm $CONF_FILE_NGINX
    fi
    echo "# For more information on configuration, see:" >> $CONF_FILE_NGINX
    echo "#   * Official English Documentation: http://nginx.org/en/docs/" >> $CONF_FILE_NGINX
    echo "#   * Official Russian Documentation: http://nginx.org/ru/docs/" >> $CONF_FILE_NGINX
    echo >> $CONF_FILE_NGINX
    echo "user nginx;" >> $CONF_FILE_NGINX
    echo "worker_processes auto;" >> $CONF_FILE_NGINX
    echo "error_log /var/log/nginx/error.log;" >> $CONF_FILE_NGINX
    echo "pid /run/nginx.pid;" >> $CONF_FILE_NGINX
    echo "events {" >> $CONF_FILE_NGINX
    echo -e "\tworker_connections  1024;" >> $CONF_FILE_NGINX
    echo -e "}" >> $CONF_FILE_NGINX
    echo >> $CONF_FILE_NGINX
    echo -e "http {" >> $CONF_FILE_NGINX
    echo -e "\tupstream apaches {" >> $CONF_FILE_NGINX
    echo -e "\t\tip_hash;" >> $CONF_FILE_NGINX
    FIN="True"
    while [[ $FIN == "True" ]]; do
        read -p "Por favor indique la IP del servidor: " SERVER_IP
        if [ -n $SERVER_IP ];then
            echo -e "\t\tserver $SERVER_IP max_fails=3 fail_timeout=5s;" >> $CONF_FILE_NGINX
        fi
        read -p "Deseá agregar otro servidor: (Y/N)" opt
        if [[ $opt == "n" ]] || [[ $opt == "N" ]];then
            FIN="False";
        fi
    done
    #echo -e "\t\tserver 192.168.50.157;" >> $CONF_FILE_NGINX
    echo -e "\t\tkeepalive 3;" >> $CONF_FILE_NGINX
    echo -e "\t}" >> $CONF_FILE_NGINX
    echo -e "\tserver{" >> $CONF_FILE_NGINX
    echo -e "\t\tlisten 80;" >> $CONF_FILE_NGINX
    echo -e "\t\tserver_name m3lb;" >> $CONF_FILE_NGINX
    echo -e "\t\taccess_log /var/log/nginx/access.log;" >> $CONF_FILE_NGINX
    echo -e "\t\terror_log /var/log/nginx/error.log;" >> $CONF_FILE_NGINX
    echo -e "\t\troot /var/www/;" >> $CONF_FILE_NGINX
    echo -e "\t\tlocation /" >> $CONF_FILE_NGINX
    echo -e "\t\t{" >> $CONF_FILE_NGINX
    echo -e "\t\t\tproxy_pass http://apaches;" >> $CONF_FILE_NGINX
    echo -e "\t\t\tproxy_set_header Host \$host:\$proxy_port;" >> $CONF_FILE_NGINX
    echo -e "\t\t\tproxy_set_header X-Real-IP \$remote_addr;" >> $CONF_FILE_NGINX
    echo -e "\t\t\tproxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;" >> $CONF_FILE_NGINX
    echo -e "\t\t\tproxy_http_version 1.1;" >> $CONF_FILE_NGINX
    echo -e "\t\t\tproxy_set_header Connection \"\";" >> $CONF_FILE_NGINX
    echo -e "\t\t}" >> $CONF_FILE_NGINX
    echo -e "\t}" >> $CONF_FILE_NGINX
    echo "}" >> $CONF_FILE_NGINX
}

# Función para arrancar y detener el servicio de Nginx
function start_stop_nginx(){
    read -p "Elija la opción a realizar\n([E]stado/[I]niciar/[D]etener/[R]einiciar/[H]abilitar/Desa[b]ilitar/[C]ancelar): " opt
    if [[ $opt == "e" ]] || [[ $opt == "E" ]];then
        systemctl status nginx.service
    elif [[ $opt == "i" ]] || [[ $opt == "I" ]];then
        systemctl start nginx.service
    elif [[ $opt == "d" ]] || [[ $opt == "D" ]];then
        systemctl stop nginx.service
    elif [[ $opt == "r" ]] || [[ $opt == "R" ]]; then
        systemctl restart nginx.service
    elif [[ $opt == "h" ]] || [[ $opt == "H" ]];then
        systemctl enable nginx.service
    elif [[ $opt == "b" ]] || [[ $opt == "B" ]];then
        systemctl disable nginx.service
    elif [[ $opt == "c" ]] || [[ $opt == "C" ]];then
        echo "Cancelado";
    else
        clear;
        start_stop_nginx;
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
    echo "           * 2.- Install NGINX                    *"
    echo "           * 3.- Crear configuración de Nginx     *"
    echo "           * 4.-                                  *"
    echo "           * 5.-                                  *"
    echo "           * 6.-                                  *"
    echo "           * 7.- Habilitar/Deshabilita Nginx      *"
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
        install_nginx;
        pause;
        menu;
        ;;
        3)
        config_nginx;
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
        start_stop_nginx;
        pause --with-msg;
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
