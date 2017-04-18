#!/bin/bash
# Titulo:       Configuración Inicial
# Fecha:        23/12/16
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción:  Muestra la configuración actual y da opciones para cambiarla
# Opciones: Ninguna
# Uso: initial-config.sh


# VARIABLES ESTATICAS DEL SCRIPT
DEPENDS_THIS_SCRIPT=(ifconfig nmap find git) # Dependencias necesarias

# VARIABLES GLOBALES DEL SCRIPT
TEST_IP=8.8.8.8
SELINUX_FILE=/etc/selinux/config
TEMP_FILE=/tmp/file.tmp
ISSUE_FILE=/etc/issue
PORT_COCKPIT_FILE=/etc/systemd/system/cockpit.socket.d/listen.conf
COCKPIT_DEFAULT_PORT=9090
NEWUSER=usuario
NEWGROUP=usuarios

# INCLUDES
path="$(dirname "$0")"
source "$path/functions-depends.sh"

# Funciónm para habilitar/deshabilitar el SELinux
function selinux {
    /usr/sbin/sestatus
    if [[ "$(/usr/sbin/getenforce)" == "Disabled" ]]; then
        opt=$(request -m "¿Desea Activarlo? Y/N " -v N)
        if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
            sed -i 's/SELINUX=disabled/SELINUX=enforcing/g' $SELINUX_FILE
            echo "SELinux habilitado..."
            pause
        fi
    else
        opt=$(request -m "¿Desea Desactivarlo? Y/N " -v N)
        if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
            sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' $SELINUX_FILE
            echo "SELinux deshabilitado..."
            pause
        fi
    fi
    opt=$(request -m "Es necesario reiniciar el servidor, ¿Desea hacerlo ahora? Y/N " -v N)
    if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
        reboot
    fi
}

# Funcion privada que se encarga de configurar correctamente el firewalld
# se usa para abrir los puertos necesarios, para una instalación desde 0
#
# esta a mitad de hacer, hace falta sacar una lista de zonas activas
# una lista de servicios asignados a la zona activa
# poner una zona activa por defecto y que el usuario la seleccione de la lista
function config_firewalld {
  # se realiza esta opción para tener en cuenta pusibles modificaciones
  firewall-cmd --reload >/dev/null 2>&1
  # Mostrar las zonas activas
  ACTIVE_ZONE=$(firewall-cmd --get-active-zone | head -n1)
  # funcion para añadir un nuevo servicio a firewalld
  firewalld_new_service --name webmin --ports 10000 -t tcp,udp
  # añadimos el servicio a la zona activa
  firewall-cmd --permanent --zone=$ACTIVE_ZONE --add-service=webmin
  # esto tenemos que usarlo si el servicio ya esta asignado a la zona
  #firewall-cmd --permanent --zone=$ACTIVE_ZONE --remove-service=webmin
}

# Funcion privada para crear un nuevo servico para firewalld
# Uso:
#   firewalld_new_service webmin 1000 tcp
# @param string -n ó --name ==> Nombre del servicio
# @param string -p ó --ports ==> puertos del servicio separados por comas
# @param string -t ó --protocols ==> protócolos del servicio separados por comas
#
# Uso:
# firewalld_new_service -n webmin --ports 45,67,89 --protocol tcp
function firewalld_new_service {
  local name=$(getparamva -m,--name "$@")
  local ports=$(getparamva -p,--ports "$@")
  local protocols=$(getparamva -t,--protocols "$@")

  if is_set $name && is_set $ports && is_set $protocols; then
    # se realiza esta opción para tener en cuenta posibles modificaciones
    firewall-cmd --reload >/dev/null 2>&1 # se pone /dev/null para que no salga la palabra success
    if [[ $(firewall-cmd --info-service=$name 2>/dev/null | head -n1) ]]; then # se redirige el error a /dev/null
      echo "El servicio: $name ya existe,"
      opt=$(request -m "¿Quiere borrarlo y volver a crearlo? S/N " -v N)
      if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
        # Borramos el servicio que ya existe
        firewall-cmd --permanent --delete-service=$1
        # Creamos el servicio para WebMin
        firewall-cmd --permanent --new-service=$1
        for proto in $protocols; do
          for port in $ports; do
            # añadimos el puerto al servicio
            firewall-cmd --permanent --service=webmin --add-port=$port/$proto
          done
        done
      fi
    else
      echo "El servicio: $name NO existe,"
      # Creamos el servicio para WebMin
      firewall-cmd --permanent --new-service=$1
      for proto in $protocols; do
        for port in $ports; do
          # añadimos el puerto al servicio
          firewall-cmd --permanent --service=$1 --add-port=$port/$proto
        done
      done
    fi
  else
    echo "faltán parámetros en la función firewalld_new_service..."
  fi
}

# Funciónm para habilitar/deshabilitar el firewalld
function firewall {
    local state=$(firewall-cmd --state 2>&1 ) # 2>/dev/null 2>&1 )
    # se realiza esta opción para tener en cuenta posibles modificaciones
    firewall-cmd --reload >/dev/null 2>&1 # se pone /dev/null para que no salga la palabra success
    if [[ $state == "running" ]];then
      echo "Estado del FirewallD: $state"
      opt=$(request -m "¿Desea detener el firewall? S/N " -v N)
      if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
        systemctl stop firewalld.service
        opt=$(request -m "¿Quiere realizar los cambios de forma permanente (on boot)? S/N " -v N)
        if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
            # tienes que añadir al servicio de firewalld un comando de mask para que se enmascare
            # por que si no cuando se reinicia se vuelve a activar
            systemctl disable firewalld.service
            systemctl mask firewalld.service
        fi
        echo "Estado del demonio del FirewallD: "
        systemctl status firewalld.service
      fi
    else
      echo "Estado del FirewallD: $state"
      opt=$(request -m "¿Desea habilitar el firewall? S/N " -v N)
      if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
        systemctl unmask firewalld.service
        systemctl start firewalld.service
        config_firewalld
        firewall-cmd --reload >/dev/null 2>&1 # se pone /dev/null para que no salga la palabra success
        opt=$(request -m "¿Quiere realizar los cambios de forma permanente (on boot)? S/N " -v N)
        if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
            # habilitar los puertos necesarios para la instalación, webmin (crear el servicio), ssh, cockpit
            systemctl enable firewalld.service

        fi
        echo "Estado del demonio del FirewallD: "
        systemctl status firewalld.service
      fi
    fi
}

# Función para mostrar y comprobar cuales son las direcciones IP
# Sin parámetros de entrada
function network_check {
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
function internet_check {
    local count=($(ping $TEST_IP -c 5 | awk '/time=/{print substr($1,1)}'))
    if [[ ${#count[@]} -gt "4" ]]; then
        echo "Hay conectividad exterior"
    else
        echo "No hay conectividad exterior"
    fi
    for i in $(str_to_array estos,son,los,parametros); do
      echo $i
    done
}

# Función para crear el mensaje de ISSUE
# parámetro 1 sirve para dar nombre al producto
function issue_msg {
    echo "Se esta generando el mensaje que saldrá en la consola de inicio de sesión del servidor"
    if [ -e $ISSUE_FILE ];then
        rm $ISSUE_FILE
    fi
    read -p "Indique el segundo titulo del Banner: " TITLE
    #echo -e "\S\r\nKernel $(uname -r) on an \m (\l)\r\n" >> $ISSUE_FILE
    local port
    if [ -e $PORT_COCKPIT_FILE ];then
        $port=$(grep /etc/systemd/system/cockpit.socket.d/listen.conf -e "ListenStream=" | awk -F"=" 'FNR==2 {print $2}')
    else
        $port=$(grep /usr/lib/systemd/system/cockpit.socket -e "ListenStream=" | awk -F"=" '{print $2}')
    fi
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
function change_cockpit_port {
    read -p "Que puerto desea: (set by default $COCKPIT_DEFAULT_PORT)" PORT
    if [ -z $PORT ];then
        PORT=$COCKPIT_DEFAULT_PORT
    fi
    # hacer una validación de con REGEX de que es un puerto valido
    if [ $PORT == 9090 ];then
      if [ -e $PORT_COCKPIT_FILE ];then
          rm $PORT_COCKPIT_FILE
      fi
      systemctl daemon-reload
      systemctl restart cockpit.socket
      netstat -ltn
    else
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
    fi
}

# Funcion que se encarga de cambiar el nombre del equipo
function change_hostname {
  while [[ -z $hostname ]]; do
    hostname=$(request -m "Introduzca el nombre de Host")
    if [ -z $hostname ];then
      echo "Por favor indique un nombre de host valido"
    fi
  done
  read -p "¿Pertenece a un dominio? Y/N " opt
  if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
    while [[ -z $domain ]]; do
      domain=$(request -m "¿Que nombre de dominio desea usar? " -v "veridata.local")
      if [ -z $domain ];then
        echo "Por favor indique un nombre de dominio valido"
      fi
    done
  fi
  if [[ -n $hostname ]] && [[ -n $domain ]];then
    hostnamectl set-hostname "$hostname.$domain"
  fi
  if [[ -n $hostname ]] && [[ -z $domain ]];then
    hostnamectl set-hostname $hostname
  fi
}

# Función para instalar el administrador de consola de NetworkManager
function install_nmtui {
    echo "Instalando el Gestor de Consola de NetworkManager"
    dnf -y install NetworkManager-tui.x86_64
}

# Función para instalar el administrador de consola de NetworkManager
function install_teamviewer {
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
function install_VNC {
    echo "# Función para instalar el servidor de VNC"
}

# Función para presentar el Menú
# Sin parámetros de entrada
function menu {
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
    echo "           * 13.- Cambiar el nombre a la maquina  *"
    echo "           *                                      *"
    echo "           * 0.- Salir                            *"
    echo "           ****************************************"
    echo
    option=$(request -m "           Elija una opción: " -v 0)
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
        pause -m;
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
        install_VNC;
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
        issue_msg;
        pause;
        menu;
        ;;
        13)
        change_hostname;
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
