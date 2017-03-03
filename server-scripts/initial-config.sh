#!/bin/bash
# Titulo:       Configuración Inicial
# Fecha:        23/12/16
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción:  Muestra la configuración actual y da opciones para cambiarla
# Opciones: Ninguna
# Uso: initial-config.sh


# VARIABLES ESTATICAS
DEPENDS=(ifconfig nmap find git) # Dependencias necesarias
DIRS=(/usr/bin /usr/sbin /bin) # Directorios de busqueda
MASKS_CIDR=(32 31 30 29 28 27 26 25 24 23 22)
MASKS_DEC=(255.255.255.255 255.255.255.254 255.255.255.252 255.255.255.248 255.255.255.240 255.255.255.224 255.255.255.192 255.255.255.128 255.255.255.0 255.255.254.0 255.255.252.0)

# VARIABLES GLOBALES
TEST_IP=62.15.168.50
SELINUX_FILE=/etc/selinux/config
TEMP_FILE=/tmp/file.tmp
ISSUE_FILE=/etc/issue
PORT_COCKPIT_FILE=/etc/systemd/system/cockpit.socket.d/listen.conf
NEWUSER=usuario
NEWGROUP=usuarios

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

# Función que se encarga de crear cualquier usuario en el sistema, de manera básica hay parametros que se omiten en la creación del mismo investigar sobre el tema
function create_user() {
    echo "Crearemos un usuario del sistema"
    read -p "Indique el usuario: (default:$NEWUSER) " NEWUSER
    if [ -z $NEWUSER ];then
        echo "el usuario es vacío"
        NEWUSER=usuario
    fi
    read -p "Cuál es el nombre del usuario completo: " complete_name_user
    read -p "Indique el grupo al que pertenece: (default:$NEWGROUP) " NEWGROUP
    if [ -z $NEWGROUP ];then
        echo "el grupo es vacío"
        NEWGROUP=usuarios
    fi
    echo "El directorio home del usuario es: /home/$NEWUSER"
    read -p "¿Es correcto? (Y/N): " opt
    if [[ $opt == "n" ]] || [[ $opt == "n" ]];then
        read -e -p "Indique la ruta completa del directorio HOME: " PATH_HOME
    fi
    echo "Estos los datos del usuario: "
    echo -e "Usuario:\t\t$NEWUSER"
    echo -e "Nombre:\t\t$complete_name_user"
    echo -e "Grupo principal:\t$NEWGROUP"
    echo -e "Carpeta Home:\t$PATH_HOME"
    if [[ $opt == "y" ]] || [[ $opt == "Y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
        #groupadd -f $NEWGROUP
        #useradd -M -d $PATH_HOME -c "$complete_name_user" -g $NEWGROUP $NEWUSER
        echo "Por favor introduzca la contraseña: "
        #passwd $NEWUSER
    fi
}

# Funciónm para habilitar/deshabilitar el SELinux
function selinux() {
    /usr/sbin/sestatus
    echo
    if [[ "$(/usr/sbin/getenforce)" == "Disabled" ]]; then
        read -p "¿Desea Activarlo? Y/N " opt
        if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
            sed -i 's/SELINUX=disabled/SELINUX=enforcing/g' $SELINUX_FILE
            echo "SELinux habilitado..."
            read -s -t 3
        fi
    else
        read -p "¿Desea Desactivarlo? Y/N " opt
        if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
            sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' $SELINUX_FILE
            echo "SELinux deshabilitado..."
            read -s -t 3
        fi
    fi
    read -p "Es necesario reiniciar el servidor, ¿Desea hacerlo ahora? Y/N " opt
    if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
        reboot
    fi
}

# Funciónm para habilitar/deshabilitar el firewalld
function firewall() {
    systemctl status firewalld.service
    read -p "Que desea hacer, ¿Habilitar ó Deshabilitar el firewall? H/D " opt
    if [[ $opt == "h" ]] || [[ $opt == "H" ]];then
        read -p "¿Quiere realizar los cambios de forma permanente (on boot)? Y/N " opt
        if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
            systemctl enable firewalld.service
        fi
        systemctl start firewalld.service
    elif [[ $opt == "d" ]] || [[ $opt == "D" ]]; then
        read -p "¿Quiere realizar los cambios de forma permanente (on boot)? Y/N " opt
        if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
            systemctl disable firewalld.service
        fi
        systemctl stop firewalld.service
    fi
}

# Función para mostrar y comprobar cuales son las direcciones IP
# Sin parámetros de entrada
function network_check() {
    IP_LIST=($(ifconfig | awk '/inet /{print substr($2,1)}'))
    for ip in ${IP_LIST[@]}; do
        echo $ip
        #if [ ${#IP_LIST[$ip]} = '127.0.0.1' ]; then # Esto es para quitar el localhost
        #    echo ${IP_LIST[$ip]};
        #fi
    done
    if [[ ${#IP_LIST[@]} -gt "0" ]]; then
        echo " Hay conectividad de red"
        echo
        echo ${#IP_LIST[@]};
        #for ip in ${#IP_LIST[@]}; do
        #    echo $ip
        #done
    else
        echo "No hay conectividad de red"
    fi
}

# Función para comprobar la conectividad con internet
# Sin parámetros de entrada
function internet_check() {
    local count=($(ping $TEST_IP -c 5 | awk '/time=/{print substr($1,1)}'))
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

# Función para crear el mensaje de ISSUE
# parámetro 1 sirve para dar nombre al producto
function issue_msg() {
    echo "Se esta generando el mensaje que saldrá en la consola de inicio de sesión del servidor"
    if [ -e $ISSUE_FILE ];then
        rm $ISSUE_FILE
    fi
    local port
    if [ -e $PORT_COCKPIT_FILE ];then
        $port=$(grep /etc/systemd/system/cockpit.socket.d/listen.conf -e "ListenStream=" | awk -F"=" 'FNR==2 {print $2}')
    else
        $port=$(grep /usr/lib/systemd/system/cockpit.socket -e "ListenStream=" | awk -F"=" '{print $2}')
    fi
    read -p "Indique el segundo titulo del Banner: " TITLE
    #echo -e "\S\r\nKernel $(uname -r) on an \m (\l)\r\n" >> $ISSUE_FILE
    echo "     Veridata S.L.       $TITLE" > $ISSUE_FILE
    echo "----------------------------------------------" >> $ISSUE_FILE
    echo "Configurado por:        Carlos de la Torre" >> $ISSUE_FILE
    echo "Sistema:                \S \s \v" >> $ISSUE_FILE
    echo "Kernel:                 \r on an \m (\l)" >> $ISSUE_FILE
    echo "Nombre Servidor:        \n.\o" >> $ISSUE_FILE
    echo >> $ISSUE_FILE
    echo -e "Consola de Administración:\r\n\thttps://\4:$port/ or https://[\6]:$port/" >> $ISSUE_FILE
    cat $ISSUE_FILE
}

# Función que cambia el puerto de administración de cockpit al que quiere el usuario
function change_cockpit_port() {
    read -p "Que puerto desea: (set by default 0)" PORT
    # hacer una validación de con REGEX de que es un puerto valido
    if [ $PORT == 0 ];then
        rm $PORT_COCKPIT_FILE
        exit
    fi
    if [ -e $PORT_COCKPIT_FILE ];then
        rm $PORT_COCKPIT_FILE
    fi
    # esto lo tienes que poner para que se reconozca de manera automatica
    if [ ! -d /etc/systemd/system/cockpit.socket.d ];then
        mkdir /etc/systemd/system/cockpit.socket.d
    fi
    echo -e "[Socket]\r\nListenStream=\r\nListenStream=$PORT" > $PORT_COCKPIT_FILE
    echo "Se ha cambiado el puerto de cockpit a: $PORT"
    systemctl daemon-reload
    systemctl restart cockpit.socket
    echo "Se ha reiniciado el socket de cockpit"
    systemctl status cockpit.socket
    netstat -ltn
}

# Función para instalar el administrador de consola de NetworkManager
function install_nmtui() {
    echo "Instalando el Gestor de Consola de NetworkManager"
    dnf -y install NetworkManager-tui.x86_64
}

# Función para instalar el administrador de consola de NetworkManager
function install_teamviewer() {
    echo "Comienza la instalación de TeamViewer"
    if [ -e $TEMP_FILE ];then
        rm $TEMP_FILE
    fi
    rpm --import http://download.teamviewer.com/download/TeamViewer_Linux_PubKey.asc
    wget http://download.teamviewer.com/download/teamviewer.i686.rpm -O $TEMP_FILE
    mv $TEMP_FILE /tmp/teamviewer.i686.rpm
    dnf -y install /tmp/teamviewer.i686.rpm
}

# Función para instalar el servidor de VNC
function install_tigerVNC() {
    echo "# Función para instalar el servidor de VNC"
}

# Función para presentar el Menú
# Sin parámetros de entrada
function menu() {
    clear;
    echo
    echo "           ****************************************"
    echo "           *          Esto es el Menú             *"
    echo "           * 1.- Crear el usuario                 *"
    echo "           * 2.- Cambiar estado de SELinux        *"
    echo "           * 3.- Cambiar estado de Firewall       *"
    echo "           * 4.- Prueba de pausa                  *"
    echo "           * 5.- Prueba de red                    *"
    echo "           * 6.- Prueba de internet               *"
    echo "           * 7.- Instalar NMTui                   *"
    echo "           * 8.- Instalar TeamViewer              *"
    echo "           * 9.- Instalar TigerVNC                *"
    echo "           * 10.- Comprobar dependencias          *"
    echo "           * 11.- Cambiar puerto de Cockpit       *"
    echo "           * 12.- Crear mensage de ISSUE          *"
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
        create_user;
        pause;
        menu;
        ;;
        2)
        selinux;
        pause;
        menu;
        ;;
        3)
        firewall;
        pause;
        menu;
        ;;
        4)
        pause --with-msg;
        menu;
        ;;
        5)
        network_check;
        pause;
        menu;
        ;;
        6)
        internet_check;
        pause;
        menu;
        ;;
        7)
        install_nmtui;
        pause;
        menu;
        ;;
        8)
        install_teamviewer;
        pause;
        menu;
        ;;
        9)

        pause;
        menu;
        ;;
        10)
        check_depends;
        pause;
        menu;
        ;;
        11)
        change_cockpit_port;
        pause;
        menu;
        ;;
        12)
        issue_msg "V·COMM Madrid";
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
