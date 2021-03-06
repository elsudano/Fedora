#!/bin/bash
# Titulo:       Configuración e instalación de Webmin
# Fecha:        23/12/16
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción:  Instalación y configuración de WebMin
# Opciones: Ninguna
# Uso: install-webmin.sh


# VARIABLES ESTATICAS DEL SCRIPT
# poner estas en el array para que se las pase a function-depends DEPENDS=(dnf git perl wget rpm) # Dependencias necesarias

# VARIABLES GLOBALES DEL SCRIPT
TEST_IP=8.8.8.8
REPO_WEBMIN_FILE=/etc/yum.repos.d/webmin.repo
BASE_DIR_MODULES=/usr/libexec/webmin/
NAME_OF_MODULES=(adsl-client bind8 bacula-backup bandwidth burner cluster-passwd
cluster-copy cluster-cron cluster-shell cluster-software cluster-usermin
cluster-useradmin cluster-webmin dovecot exim fail2ban fetchmail heartbeat
ipsec jabber firewall firewall6 nis openslp pap ppp-client pptp-client
pptp-server postfix proftpd procmail qmailadmin sendmail shorewall shorewall6
spam squid sarg syslog-ng vgetty wuftpd webalizer iscsi-client iscsi-server
iscsi-tgtd iscsi-target idmapd filter tunnel heartbeat mon exports nis lpadmin
samba file)

# INCLUDES
path="$(dirname "$0")"
source "$path/functions-depends.sh"

# Función que se encarga de la instalación de WebMin
function install_webmin(){
    sudo dnf -y install perl-Time-Piece
    if [ -e $REPO_WEBMIN_FILE ];then
        rm $REPO_WEBMIN_FILE
    fi
    echo -e "[Webmin]\r\nname=Webmin Distribution Neutral\r\n#baseurl=http://download.webmin.com/download/yum\r\nmirrorlist=http://download.webmin.com/download/yum/mirrorlist\r\nenabled=1" > $REPO_WEBMIN_FILE
    cat $REPO_WEBMIN_FILE
    wget http://www.webmin.com/jcameron-key.asc -O /tmp/key.asc
    rpm --import /tmp/key.asc
    dnf -y install webmin
    systemctl daemon-reload
    systemctl enable webmin.service
    opt=$(request -m "Es necesario reiniciar el servidor, ¿Desea hacerlo ahora? Y/N " -v N)
    if [[ $opt == "y" ]] || [[ $opt == "y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
        reboot
    fi
}

# Función que nos permite eliminar los modulos que no vamos a usar
function delete_modules(){
    # TODO: esta función se puede optimizar de momento se queda así para realizar
    # la instalación necesaria
    echo "Eliminando modulos"
    for MODULE in ${NAME_OF_MODULES[@]}
    do
      rm -fR $BASE_DIR_MODULES$MODULE
      #echo "delete $BASE_DIR_MODULES$MODULE"
    done
    systemctl daemon-reload
    systemctl restart webmin.service
    echo "Recuerde actualizar los módulos desde la interfaz gráfica"
}

# Función que se encarga de la configuración miníma de WebMin
function config_webmin(){
    echo "Configuración"
    #wget http://theme.winfuture.it/bwtheme.wbt.gz -O $TEMP_FILE
    #/usr/libexec/webmin/bootstrap
}

# Función que se encarga de comprobar si webmin está instalado con todos sus módulos
function check_instalation_webmin(){
    echo "La instalación de WebMin está:"
    systemctl daemon-reload
    systemctl status webmin.service
}

# Función para presentar el Menú
# Sin parámetros de entrada
function menu() {
    clear;
    echo
    echo "           ****************************************"
    echo "           *          Esto es el Menú             *"
    echo "           * 1.- Comprobar dependencias           *"
    echo "           * 2.- Instalación de WebMin            *"
    echo "           * 3.- Configuración de WebMin          *"
    echo "           * 4.- Borrado de modulos no usados     *"
    echo "           * 5.- Instalación de modulos           *"
    echo "           * 6.- Comprobar instalación WebMin     *"
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
        install_webmin;
        pause;
        menu;
        ;;
        3)
        config_webmin;
        pause;
        menu;
        ;;
        4)
        delete_modules;
        pause;
        menu;
        ;;
        5)

        pause;
        menu;
        ;;
        6)
        check_instalation_webmin;
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
