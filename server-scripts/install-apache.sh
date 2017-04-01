#!/bin/bash
# Titulo:       Instalación y configuración de Apache
# Fecha:        23/12/16
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción: Instalación de Apache y configuración de módulos
# Opciones: Ninguna
# Uso: install-apache.sh

# INCLUDES
path="$(dirname "$0")"
source "$path/functions-depends.sh"

# VARIABLES ESTATICAS DEL SCRIPT
DEPENDS_THIS_SCRIPT=(ifconfig nmap find git) # Dependencias necesarias

# VARIABLES GLOBALES DEL SCRIPT
TEST_IP=62.15.168.50
TEMP_FILE=/tmp/file.tmp
PATH_DATA_WEB=/datawww/html
PATH_DATA_VCOMM=/datawww/datavcomm
APACHE_USER=gestapa
APACHE_GROUP=datawww

# Función que se encarga de crear los directorios para los datos y el directorio root web para apache
function create_data_root_path(){
  if [ -e $PATH_DATA_WEB ] && [ -d $PATH_DATA_WEB ];then
    local opt=$(request -m "Desea utilizar el directorio $PATH_DATA_WEB como root web? (Y/N) ")
    if [ $opt == "n" ] || [ $opt == "N" ];then
      while [ -z $PATH_DATA_WEB ]
      do
        PATH_DATA_WEB=$(request -m "Indique el directorio root web ")
        if [ $opt == "n" ] || [ $opt == "N" ];then
          merr "Opción inválida..." --no-break
        fi
      done
      mkdir -p $PATH_DATA_WEB
      echo "Se ha creado el directorio $PATH_DATA_WEB para alojar la instalación WEB"
    fi
  else
    PATH_DATA_WEB=$(request -m "Indique el directorio root web " -v /datawww/html)
    mkdir -p $PATH_DATA_WEB
    echo "Se ha creado el directorio $PATH_DATA_WEB para alojar la instalación WEB"
  fi
  # Con esto nos aseguramos que el directorio de datos esta en el mismo directorio que el root
  if [ ! -e $PATH_DATA_WEB/../datavcomm ];then
    echo "Se creará el directorio 'datavcomm' al mismo nivel que $PATH_DATA_WEB/../datavcomm para alojar datos del software"
    mkdir -p $PATH_DATA_WEB/../datavcomm
  fi
}

# Función que se encarga de crear los usuarios y los grupos para el correcto funcionamiento
function create_user_and_group(){
    echo "Crearemos un usuario para apache"
    if is_set $APACHE_USER;then
        APACHE_USER=$(request -m "Indique el usuario " -v gestapa)
    fi

    local complete_name_user=$(request -m "Nombre completo del Usuario")

    if is_set $APACHE_GROUP;then
        APACHE_GROUP=$(request -m "Indique el usuario " -v datawww)
    fi
    echo "El directorio donde se alojan las webs es: $PATH_DATA_WEB"
    opt=$(request -m "¿Es correcto? (Y/N) ")

    if [[ $opt == "n" ]] || [[ $opt == "n" ]];then
        PATH_DATA_WEB=$(request -m "Nombre completo del Usuario")
    fi

    groupadd -f $APACHE_GROUP
    useradd -M -d $PATH_DATA_WEB -c "$complete_name_user" -g $APACHE_GROUP $APACHE_USER
    passwd $APACHE_USER

    if [ -e $PATH_DATA_WEB ];then
        chown -R $APACHE_USER:$APACHE_GROUP $PATH_DATA_WEB
        chmod 0775 $PATH_DATA_WEB
    else
        echo "Falta el directorio root web, para poder asignarle permisos"
    fi

    if [ -e $PATH_DATA_WEB/../datavcomm ];then
        chown -R $APACHE_USER:$APACHE_GROUP $PATH_DATA_WEB/../datavcomm
        chmod 0775 $PATH_DATA_WEB/../datavcomm
    else
        echo "Falta el directorio de datos, para poder asignarle permisos"
    fi
}

################################################################################
############################## Funciones de Script #############################
################################################################################

# Función que se encarga realizar la instalación mínima de Apache
function install_apache(){
  echo "Comienza la instalación de Apache"
  dnf -y install httpd.x86_64
  local user
  sel_user user
  # a partir de aqui tenemos que seleccionar el fichero de configuracion de
  # apache para asignarle el usuario de gestion
}

# Función que se encarga realizar la instalación de los módulos necesarios para V·COMM
function install_apache_modules(){
    echo "Instalación de SSL module"
    dnf -y install mod_ssl.x86_64
}

# Función que modifica los ficheros de configuración necesarios para la configuración basica de apache
function basic_configuration_apache(){
    echo "Buscar los ficheros de configuracion de apache y modificar solo las partes necesarias para que funcione"
    # analizar el fichero de configuracion que viene por defecto y comprobar que
    # todas las lineas que quiero estan en el por cada linea que se analize
    # tienes que mostrar un mensaje con el posible error
    #
    # Cambiar 'Listen 80' por 'Listen *:80 http'
    # Cambiar 'User apache' por 'User gestapa'
    # Cambiar 'Group apache' por 'Group datawww'
    # Cambiar 'ServerAdmin root@localhost' por 'ServerAdmin carlos.delatorre@veridata.es'
    # Cambiar 'DocumentRoot "/var/www/html"' por 'DocumentRoot "/datawww/html"'
    # Cambiar '<Directory "/var/www/html">' por '<Directory "/datawww/html">'
    # Cambiar '' por ''
    # Cambiar '' por ''
    # Cambiar '' por ''
    # Cambiar '' por ''
    # Eliminar todo lo siguiente
    #
        # Relax access to content within /var/www.
        #
        # <Directory "/var/www">
        #     AllowOverride None
        #     # Allow open access:
        #     Require all granted
        # </Directory>
    #
  }

# Función que se encarga de montar los virtual host necesarios
function create_virtual_host(){
    echo "Crear el fichero correspondiente en el directorio de configuracipon de apache"
    # elegir los datos de ICAGR
}

# Función para arrancar y detener el servicio de Apache
function start_stop_apache(){
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
        start_stop_apache;
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
    echo "           * 2-  Crear dir. Root y Data           *"
    echo "           * 3.- Crear Usuario y Grupo Apache     *"
    echo "           * 4-  Instalar Apache                  *"
    echo "           * 5.- Instalar módulos de Apache       *"
    echo "           * 6.- Configuración de Apache          *"
    echo "           * 7.- Crear Virtual Hosts              *"
    echo "           * 8.- Habilitar/Deshabilita Apache     *"
    echo "           * 9.-                                  *"
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
        create_data_root_path;
        pause;
        menu;
        ;;
        3)
        create_user_and_group;
        pause;
        menu;
        ;;
        4)
        install_apache;
        pause;
        menu;
        ;;
        5)
        install_apache_modules;
        pause;
        menu;
        ;;
        6)
        basic_configuration_apache;
        pause;
        menu;
        ;;
        7)
        create_virtual_host;
        pause;
        menu;
        ;;
        8)
        start_stop_apache;
        pause;
        menu;
        ;;
        9)

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
