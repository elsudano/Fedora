#!/bin/bash
# Titulo:       Instalación y configuración de IpTables
# Fecha:        26/01/17
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción: Instalación y configuración de las diferentes reglas de IpTables, junto con los paquetes necesarios para que los servicios y las utilidades
# Opciones: Ninguna
# Uso: install-iptables.sh


# VARIABLES ESTATICAS
DEPENDS=(ifconfig nmap find git iptables) # Dependencias necesarias
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

# Función para generar una nueva regla en el firewall
function new_rule(){
    echo "# Función para generar una nueva regla en el firewall"
}

# Función para eliminar una regla en el firewall
function delete_rule(){
    echo "# Función para eliminar una regla en el firewall"
}

# Función para crear las reglas correspondientes al balanceador de carga de una sola vez usando las funciones anteriores
function load_balancer_rules(){
    echo "# Función para crear las reglas correspondientes al balanceador de carga de una sola vez usando las funciones anteriores"
}

# Función para crear las reglas correspondientes al frontal de una sola vez usando las funciones anteriores
function front_rules(){
    echo "# Función para crear las reglas correspondientes al frontal de una sola vez usando las funciones anteriores"
}

# Función para crear las reglas correspondientes al repositorio de una sola vez usando las funciones anteriores
function repository_rules(){
    echo "# Función para crear las reglas correspondientes al repositorio de una sola vez usando las funciones anteriores"
}

# Función que muestra todas las reglas del firewall
function show_rules(){
    echo "# Función que muestra todas las reglas del firewall"
}

# Función para arrancar y detener el servicio de Apache
function start_stop_iptables(){
    read -p "Elija la opción a realizar\n([E]stado/[I]niciar/[D]etener/[R]einiciar/[H]abilitar/Desa[b]ilitar/[C]ancelar): " opt
    if [[ $opt == "e" ]] || [[ $opt == "E" ]];then
        systemctl status httpd.service
    elif [[ $opt == "i" ]] || [[ $opt == "I" ]];then
        systemctl start httpd.service
    elif [[ $opt == "d" ]] || [[ $opt == "D" ]];then
        systemctl stop httpd.service
    elif [[ $opt == "r" ]] || [[ $opt == "R" ]]; then
        systemctl restart httpd.service
    elif [[ $opt == "h" ]] || [[ $opt == "H" ]];then
        systemctl enable httpd.service
    elif [[ $opt == "b" ]] || [[ $opt == "B" ]];then
        systemctl disable httpd.service
    elif [[ $opt == "c" ]] || [[ $opt == "C" ]];then
        echo "Cancelado";
    else
        clear;
        start_stop_iptables;
    fi
}

# Función que permite redirigir el tráfico de un puerto en concreto a una maquina remota de la misma red
function port_fordwarding(){
    echo "# Función que permite redirigir el tráfico de un puerto en concreto a una maquina remota de la misma red"
    read -p "Cuál es el host remoto al que se desea realizar las peticiones: " host
    if [ -z $host ];then
        echo "El host no puede ser vacío"
        port_fordwarding;
    fi
    read -p "Cuál es el puerto del host remoto donde queremos realizar las peticiones: " port
    if [ -z $port ];then
        echo "El puerto no puede ser vacío"
        port_fordwarding;
    fi
    # esta parte se puede automatizar preguntando al sistema por la ip privada
    read -p "Cuál es la dirección ip de esta máquina: " ip
    if [ -z $ip ];then
        echo "La IP no puede estar vacía"
        port_fordwarding;
    fi
    echo "Estos son los datos: "
    echo -e "Host Remoto:\t$host"
    echo -e "Puerto Remoto:\t$port"
    echo -e "IP Local:\t$ip"
    read -p "Desea añadir las reglas: (Y/N)" opt
    if [ $opt == "s" ] || [ $opt == "S" ] || [ $opt == "y" ] || [ $opt == "Y" ];then
        echo 1 > $(buscar ip_forward)
        iptables -F
        iptables -t nat -F
        iptables -X
        iptables -t nat -A PREROUTING -p tcp --dport $port -j DNAT --to-destination $host:$port
        iptables -t nat -A POSTROUTING -p tcp -d $host --dport $port -j SNAT --to-source $ip
    else
        echo "Se Canceló la operación"
    fi
}

# Función que restaura el sistema a su estado normal, despúes de realizar las pruebas
function port_fordwarding_restore(){
    echo "# Función que restaura el sistema a su estado normal, despúes de realizar las pruebas"
}

# Función para presentar el Menú
# Sin parámetros de entrada
function menu() {
    clear;
    echo
    echo "           ****************************************"
    echo "           *          Esto es el Menú             *"
    echo "           * 1.- Comprobar dependencias           *"
    echo "           * 2.- Crear regla de iptables          *"
    echo "           * 3.- Quitar regla de iptables         *"
    echo "           * 4.- Crear Reglas para Balanceador    *"
    echo "           * 5.- Crear Reglas para Frontal        *"
    echo "           * 6.- Crear Reglas para Repositorio    *"
    echo "           * 7.- Mostrar reglas de IpTables       *"
    echo "           * 8.- Habilitar/Deshabilitar IpTables  *"
    echo "           *                                      *"
    echo "           * 9.- Función Extra                    *"
    echo "           * 10.- Deshacer Extra                  *"
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
        new_rule;
        pause;
        menu;
        ;;
        3)
        delete_rule;
        pause;
        menu;
        ;;
        4)
        load_balancer_rules;
        pause;
        menu;
        ;;
        5)
        front_rules;
        pause;
        menu;
        ;;
        6)
        repository_rules;
        pause;
        menu;
        ;;
        7)
        show_rules;
        pause;
        menu;
        ;;
        8)
        start_stop_iptables;
        pause;
        menu;
        ;;
        9)
        port_fordwarding;
        pause;
        menu;
        ;;
        10)
        port_fordwarding_restore;
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
