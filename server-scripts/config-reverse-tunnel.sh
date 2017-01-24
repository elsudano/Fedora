#!/bin/bash
# Titulo:       Creación de los ficheros necesarios SSH
# Fecha:        23/01/17
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción: Se generan los ficheros con las claves publicas y privadas para la conexión remota mediante SSH
# Opciones: Ninguna
# Uso: config-reverse-tunnel.sh


# VARIABLES ESTATICAS
DEPENDS=(ssh-copy-id ssh-keygen ssh) # Dependencias necesarias
DIRS=(/usr/bin /usr/sbin /bin) # Directorios de busqueda
MASKS_CIDR=(32 31 30 29 28 27 26 25 24 23 22)
MASKS_DEC=(255.255.255.255 255.255.255.254 255.255.255.252 255.255.255.248 255.255.255.240 255.255.255.224 255.255.255.192 255.255.255.128 255.255.255.0 255.255.254.0 255.255.252.0)

# VARIABLES GLOBALES
TEST_IP=62.15.168.50
TEMP_FILE=/tmp/file.tmp
PATH_KEY_FILE=""
REMOTE_USER=""
REMOTE_HOST=""
REMOTE_PORT=""

# FUNCIONES

# Función para deter la ejecución con o sin mensaje
# parámetro de entrada $1 == --with-msg para poner mensaje (opcional)
# #parámetro de entrada $2 == cadena de texto con el mensaje (opcional)
function pause() {
    if [[ $1 == "--with-msg" ]] && [[ $2 != "" ]]; then
        read -p "$2";
    elif [[ $1 == "--with-msg" ]]; then
        read -p "Presione Enter para continuar o Ctrl+C para cancelar.";
    elif [[ $1 == "--without-timeout" ]]; then
        read -s
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

# Función que genera las claves pareadas de rsa para la conexión sin contraseña al servidor ssh
function generate_keys(){
    read -p "Por favor indique la dirección del fichero: " PATH_KEY_FILE
    read -p "Un comentario descriptivo: " comment
    #echo -e "ssh-keygen -t rsa -b 2048 -C $comment -f $PATH_KEY_FILE"
    if [ -n "$PATH_KEY_FILE" ];then
        ssh-keygen -t rsa -b 2048 -C $comment -f $PATH_KEY_FILE
    else
        echo "Tiene que indicar la ruta del fichero de claves"
    fi
}

# Función que copia la parte publica de la clave al servidor remoto
function copy_public_key(){
    if [ -z "$PATH_KEY_FILE" ];then
        read -p "Introduzca el path completo del fichero (sin .pub): " PATH_KEY_FILE
    fi
    read -p "Introduzca el usuario de conexión remota: " REMOTE_USER
    read -p "Introduzca la dirección del host remoto: " REMOTE_HOST
    read -p "Introduzca el puerto de conexión (por defecto 22) " REMOTE_PORT
    local temp="$PATH_KEY_FILE.pub"
    if [ -z "$REMOTE_PORT" ];then
        #echo "ssh-copy-id -i $PATH_KEY_FILE.pub $REMOTE_HOST"
        ssh-copy-id -i $temp $REMOTE_USER@$REMOTE_HOST
    else
        #echo "ssh-copy-id -i $PATH_KEY_FILE.pub $REMOTE_HOST -p $REMOTE_PORT"
        ssh-copy-id -i $temp $REMOTE_HOST -p $REMOTE_USER@$REMOTE_PORT
    fi
}

# Función que se encarga de crear los usuarios y los grupos para el correcto funcionamiento
# Opción de Mejora: lanzar un ping que permita mantener la conexión abierta.
function create_reverse_tunnel(){
    if [ -n "$PATH_KEY_FILE" ] && [ -n "$REMOTE_USER" ] && [ -n "$REMOTE_HOST" ] && [ -n "$REMOTE_PORT" ];then
        echo "Desea utilizar los siguientes parametros: "
        echo "Fichero de Key: $PATH_KEY_FILE"
        echo "Usuario: $REMOTE_USER"
        echo "Host remoto: $REMOTE_HOST"
        echo "Puerto: $REMOTE_PORT"
        read -p "Seleccione: (Y/N): " opt
        if [[ $opt == "n" ]] || [[ $opt == "N" ]];then
            PATH_KEY_FILE="";
            REMOTE_USER="";
            REMOTE_HOST="";
            REMOTE_PORT="";
            menu;
        fi
    else
        read -p "Introduzca el path completo del fichero (sin .pub): " PATH_KEY_FILE
        read -p "Introduzca el usuario de conexión remota: " REMOTE_USER
        read -p "Introduzca la dirección del host remoto: " REMOTE_HOST
        read -p "Introduzca el puerto de conexión (por defecto 22): " REMOTE_PORT

    fi
    read -p "Introduzca el puerto abierto en el host remoto: " remote_open_port
    read -p "Introduzca el puerto de escucha en localhost: " local_listen_port
    #echo "ssh -i $PATH_KEY_FILE -N -L $local_listen_port:localhost:$remote_open_port $REMOTE_HOST -p $REMOTE_PORT &"
    ssh -o "StrictHostKeyChecking no" -i $PATH_KEY_FILE -N -L $local_listen_port:localhost:$remote_open_port $REMOTE_USER@$REMOTE_HOST -p $REMOTE_PORT &
}

# Función que se encarga borrar los ficheros de las claves privadas
function show_tunnels(){
    echo -e "Los tuneles abiertos son los siguientes:\r\n"
    ps -e -o pid,command | grep "ssh -o StrictHostKeyChecking no"
}

# Función que se encarga borrar los ficheros de las claves privadas
function close_tunnel(){
    ps -e -o pid,command | grep "ssh -o StrictHostKeyChecking no"
    read -p "Indique el PID del tunnel que desea cerrar: " pid
    if [ -n "$pid" ];then
        kill $pid
        echo "Se ha cerrado el tunel $pid"
    else
        echo "Se cancelo el cierre"
    fi
}

# Función que se encarga borrar los ficheros de las claves privadas
function delete_keys(){
    echo "hacer un listado con ll y permitir seleccionar cual de todos borrar"
    echo "pedir al usuario cual es el path donde se almacenan sus credenciales"
}

# Función para presentar el Menú
# Sin parámetros de entrada
function menu() {
    clear;
    echo
    echo "           ****************************************"
    echo "           *          Esto es el Menú             *"
    echo "           * 1.- Comprobar Dependencias           *"
    echo "           * 2.- Generar claves priv. y pub.      *"
    echo "           * 3.- Copiar clave publica a remoto    *"
    echo "           * 4.- Crear los tuneles de conexión    *"
    echo "           * 5.- Mostrar los tuneles abiertos     *"
    echo "           * 6.-                                  *"
    echo "           * 7.- Cerrar los tuneles abiertos      *"
    echo "           * 8.- Borrar las claves                *"
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
        generate_keys;
        pause --without-timeout;
        menu;
        ;;
        3)
        copy_public_key;
        pause --without-timeout;
        menu;
        ;;
        4)
        create_reverse_tunnel;
        pause;
        menu;
        ;;
        5)
        show_tunnels;
        pause;
        menu;
        ;;
        6)

        pause;
        menu;
        ;;
        7)
        close_tunnel;
        pause;
        menu;
        ;;
        8)
        delete_keys;
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
