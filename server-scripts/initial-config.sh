#!/bin/bash
# Titulo:       Configuración Inicial
# Fecha:        15/01/17
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción:  Muestra la configuración actual y da opciones para cambiarla
# Opciones: Ninguna
# Uso: initial-config.sh


# VARIABLES ESTATICAS
DEPENDS=(ifconfig nmap find)
MASKS_CIDR=(32 31 30 29 28 27 26 25 24 23 22)
MASKS_DEC=(255.255.255.255 255.255.255.254 255.255.255.252 255.255.255.248 255.255.255.240 255.255.255.224 255.255.255.192 255.255.255.128 255.255.255.0 255.255.254.0 255.255.252.0)

# VARIABLES GLOBALES
TEST_IP=62.15.168.50

# FUNCIONES

# Función para deter la ejecución con o sin mensaje
# parámetro de entrada $1 == with-msg para poner mensaje
function pause() {
    if [ $1 == "with-msg" ]; then
        read -p "Presione Enter para continuar o Ctrl+C para cancelar.";
    else
        read -s
    fi
}

# Función para saber si se esta utilizando root
function is_root {
    if [[ "$(whoami)" != "root" ]]; then
        echo "Tiene que ejecutar este script con permisos de administrador";
        exit;
    fi
}

# Función para mostrar y comprobar cuales son las direcciones IP
# Sin parámetros de entrada
function network_check() {
    ifconfig | awk '/inet /{print substr($2,1)}'
}

# Función para comprobar la conectividad con internet
# Sin parámetros de entrada
function internet_check() {
    count=($(ping $TEST_IP -c 5 | awk '/time=/{print substr($1,1)}'))
    if [[ ${#count[@]} -gt "4" ]]; then
        echo "Hay conectividad exterior"
    else
        echo "No hay conectividad exterior"
    fi
}

# Funcion de wrapper para find
# parámetro de entrada $1 lo que queremos buscar
function buscar(){
    if [ $1 != "" ]; then
        local retval=$(find / -name $1)
    else
        echo "Falta el parámetro para buscar"
    fi
    echo $retval
}

# Función que se encarga de buscar las dependencias
function check_depends() {
for depend in ${DEPENDS[@]}
do
    df=($(buscar $depend)) # variable df = directorios de ficheros
    if [[ ${#df[@]} -gt "0" ]]; then
        echo "$depend encontrado"
    else
        echo "$depend NO encontrado"
    fi
done
}

# Función para presentar el Menú
# Sin parámetros de entrada
function menu() {

echo
echo "****************************************"
echo "*          Esto es el Menú             *"
echo "* 1.- Crear el usuario                 *"
echo "* 2.- Prueba de pausa                  *"
echo "* 3.- Prueba de red                    *"
echo "* 4.- Prueba de internet               *"
echo "* 5.- Comprobar dependencias           *"
echo "*                                      *"
echo "* 0.- Salir                            *"
echo "****************************************"
read -p "Elija una opción: " option
case $option in
    0)
    exit;
    ;;
    1)
    crear_usuario;
    ;;
    2)
    pause with-msg;
    ;;
    3)
    network_check;
    menu;
    ;;
    4)
    internet_check;
    menu;
    ;;
    5)
    check_depends;
    ;;
    *)
    echo "Opción no permitida";
    exit;
    ;;
esac
}

is_root
menu
