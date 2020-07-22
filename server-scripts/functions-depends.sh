#!/bin/bash
# Titulo:       Dependencias de funciones
# Fecha:        21/03/17
# Autor:        Carlos de la Torre
# Versión:      1.0
# Descripción: Se utilizan las diferentes funciones que hay en este script para
# los demas scripts donde se realiza una inclusión del mismo.
# Opciones: Ninguna
# Uso: functions-depends.sh

# VARIABLES ESTATICAS
# Dependencias necesarias
DEPENDS=(rpm alternatives systemctl dnf tar ip telnet basename cat cp rm chown chmod sed xargs printf tr)
# Directorios de busqueda
DIRS=(/usr/bin /usr/sbin /bin)
# TEST_IP=62.15.168.50
FALSE=1
TRUE=0
SEPARATOR=','
TEST_IP=8.8.8.8

################################################################################
############################## Funciones genéricas #############################
################################################################################

# Función que se encarga de buscar las dependencias
function check_depends() {
  #if [[ -n $1 ]]
    # Esto hay que arreglarlo es para poder usar esta funcion en los demas
    # scripts aparte de en este mismo se hace asi para reaprovechar el codigo
    # se tiene que pasar por parametros el array con las dependencias y añadirlas
    # al array que tiene este propio script
  #  declare -a DEPENDS=("${!1}")
  #fi
  for depend in ${DEPENDS[@]}
  do
    hit=0
    for dir in ${DIRS[@]}
    do
      if [ -x "$dir/$depend" ]; then
        #if [[ -n $1 ]]
          echo "Dependencia encontrada: $depend"
        #fi
      hit=1
      break;
      fi
    done
    if [ $hit == 0 ]; then
      echo "Dependencia NO encontrada: $depend"
    fi
  done
}

# Función para deter la ejecución con o sin mensaje
# parámetro de entrada $1 == -m para poner mensaje (opcional)
# #parámetro de entrada $2 == cadena de texto con el mensaje (opcional)
function pause() {
    # check_depends hay que ponerlo para que se compruebe dependencia en todas las funciones
    if [[ $1 == "-m" ]] && [[ $2 != "" ]]; then
        read -p "$2";
    elif [[ $1 == "-m" ]]; then
        read -p "Presione Enter para continuar o Ctrl+C para cancelar.";
    else
        read -s -t 3
    fi
}

# Función para saber si se esta utilizando root
function is_root {
  if [[ $EUID -ne 0 ]]; then
      echo
      echo " Tiene que ejecutar este script con permisos de administrador";
      echo
      exit;
  fi
}

# Función para comprobar si una variable está seteada
function is_set() {
    local retval=$FALSE
    if [[ -n "$1" ]]; then
    retval=$TRUE
    fi
    return $retval

}

# Función para solicitar un valor, por la entrada de datos
# Tiene dos parametros el primero -m es para mostrar el mensaje
# El segundo -v es para solicitar el valor por defecto
# Uso:
#   variable=$(request -m "Introduzca el nombre" -v carlos)
function request() {
  #check_depends
  local retval=""
  local msg=$(getparamv -m "$@")
  msg=${msg:-"Introduzca el valor"}
  local defv=$(getparamv -v "$@")
  if is_set $defv; then
    if ! hasparam -s "$@"; then
      read -e -p "$msg (default: $defv): " retval
    else
      echo | read -e -p "$msg (default: $defv): " retval
    fi
    retval=${retval:-$defv}
  else
    if ! hasparam -s "$@"; then
      read -e -p "$msg: " retval
    else
      echo | read -e -p "$msg: " retval
    fi
  fi
  echo $retval
}

# Función para obtener el valor del parámetro a continuación del indicado
# Uso:
#   getparamv -n -p P1 -n N1
#   getparamv -x "$@" devuelve el primer valor del array
# @param string $1 ==> Parámetro a buscar dentro del conjunto de parámetros
# @param string $2 ==> Parámetros a buscar
function getparamv {
    local retval=""
    for i in $(seq 2 $#) ; do
        if [ "${@:$i:1}" == "$1" ] && is_set "${@:$((i+1)):1}"; then
            retval="${@:$((i+1)):1}"
                break
        fi
    done
    echo $retval
}

# Función para obtener el valor de un parametro dado, esta función da la opción
# de poder utilizar parametros "cortos" o "largos"
#
# @param $1 string con los parametros que se desean buscar separados por comas
#   ejem: (-p,--ports)
# @param $2 array con los parametros y los valores en donde se desea buscar
#   ejem: (-t 60 --ports 45,67,89 --name dns -j tcp) == $@
# Uso:
# valor = $(getparam -p,--ports "$@")
function getparamva {
    local retval=""
    
    for i in $(str_to_array $1); do
      retval=$(getparamv $i $2)
      if is_set $retval; then
        break;
      fi
    done
    echo $retval
}

# Función para comprobar que existe un parámetro
function hasparam {
    local retval=$FALSE
    for i in $(seq 2 $#); do
        if [ "${@:$i:1}" == "$1" ]; then
            retval=$TRUE
            break
        fi
    done
    return $retval
}

# Funcion que se encarga de convertir una cadena de texto en un array
# @param $1 string cadena a convertir en array
# @param $2 string separador por el cual se dividira la cadena [optional]
#
# @note si el segundo parámetro no se utiliza el separador es el que se define al
# principio del script.
#
# Uso:
#   str_to_array estos,son,los,parametros ,
function str_to_array {
  if is_set $2; then
      SEPARATOR=$2
  fi
  IFS=$SEPARATOR read -ra tmp <<< "$1"
  echo ${tmp[@]}
}

# Funcion de wrapper para find
# parámetro de entrada $1 lo que queremos buscar
function search(){
    if [ $1 != "" ]; then
        local retval=$(find / -name $1)
    else
        echo "Faltán parámetros para buscar"
    fi
    echo $retval
}



# Muestra información relevante para el usuario
function minfo() {
    if hasparam --no-break "$@"; then
        echo "[INFO] $1"
    else
        pause -m "[INFO] $1 [Pulse ENTER...]"
    fi
}

# Muestra un error al usuario
function merr() {
    if hasparam --no-break "$@"; then
        echo "[ERROR] $1"
    else
        pause -m "[ERROR] $1 [Pulse ENTER...]"
    fi
}

# Función que se encarga de crear cualquier usuario en el sistema,
# de manera básica hay parametros que se omiten en la creación del
# mismo investigar sobre el tema
function create_user() {
    echo "Crearemos un usuario del sistema"
    NEWUSER=$(request -m "Indique el usuario " -v usuario)
    if ! is_set $NEWUSER; then
        echo "el usuario es vacío"
        NEWUSER=usuario
    fi
    complete_name_user=$(request -m "Cuál es el nombre del usuario completo " -v Usuario)
    NEWGROUP=$(request -m "Indique el grupo al que pertenece " -v users)
    if ! is_set $NEWGROUP; then
        echo "el grupo es vacío"
        NEWGROUP=usuarios
    fi
    echo "El directorio home del usuario es: /home/$NEWUSER"
    opt=$(request -m "¿Es correcto? (Y/N) " -v N)
    if [[ $opt == "n" ]] || [[ $opt == "n" ]];then
        read -e -p "Indique la ruta completa del directorio HOME: " PATH_HOME
    fi
    echo "Estos los datos del usuario: "
    echo -e "Usuario:\t\t$NEWUSER"
    echo -e "Nombre:\t\t$complete_name_user"
    echo -e "Grupo principal:\t$NEWGROUP"
    echo -e "Carpeta Home:\t$PATH_HOME"
    opt=$(request -m "¿Es correcto? (Y/N) " -v N)
    if [[ $opt == "y" ]] || [[ $opt == "Y" ]] || [[ $opt == "s" ]] || [[ $opt == "S" ]];then
        groupadd -f $NEWGROUP
        useradd -M -d $PATH_HOME -c "$complete_name_user" -g $NEWGROUP $NEWUSER
        echo "Por favor introduzca la contraseña: "
        passwd $NEWUSER
    fi
}


# Función para seleccionar el usuario que se desea de los que pertenecen al sistema
# @param string $1 => Nombre de la variable donde se almacenará el usuario seleccionado
# @param string $2 ()=>
# @param string $3 =>
function sel_user(){

    ! is_set $1 && merr "Falta el parámetro 1: nombre de la variable" && menu && exit

    local vtmp_uuid=$2 && ! is_set $vtmp_uuid && vtmp_uuid="1000"
    local vtmp_ouid=$3 && ! is_set $vtmp_ouid && vtmp_ouid=$vtmp_uuid

    local vtmp_i=0
    local vtmp_users
    local vtmp_sel=""

    local vtmp_filter=$(cat /etc/passwd | awk -vuuid=$vtmp_uuid -vouid=$vtmp_ouid  -F':' '$3>=uuid && $4>=ouid {print $1}')

    # while must be in the main shell ! (Environment variables)
    is_set $vtmp_filter && \
    while read vtmp_user;
    do
        vtmp_users[$vtmp_i]=$vtmp_user
        ((vtmp_i+=1))
        echo " $vtmp_i ) $vtmp_user"
    done <<< "$vtmp_filter" # here-string

    if [ "$vtmp_i" == "0" ]
    then
    merr "No existen usuarios disponibles, cree un usuario y reinicie la ejecución" && menu && exit
    fi

    vtmp_sel=$(request -m "Introduzca el número de usuario")

    while [ "$vtmp_sel" -lt "1" ] || [ "$vtmp_sel" -gt "$vtmp_i" ];
    do
        merr "Opción inválida..." --no-break
        vtmp_sel=$(request -m "Introduzca el número de usuario")
    done

    eval $1="${vtmp_users[$((vtmp_sel-1))]}"
}

# Función para seleccionar el usuario que se desea de los que pertenecen al sistema
# @param string $1 => Nombre de la variable donde se almacenará el usuario seleccionado
function sel_group(){

    ! is_set $1 && merr "Falta el parámetro 1: nombre de la variable" && menu && exit

    local vtmp_guid=$2 && ! is_set $vtmp_guid && vtmp_guid="1000"

    local vtmp_i=0
    local vtmp_groups
    local vtmp_sel=""

    local vtmp_filter=$(cat /etc/group | awk -vguid=$vtmp_guid -F':' '$3>=guid {print $1}')

    # while must be in the main shell ! (Environment variables)
    is_set $vtmp_filter && \
    while read vtmp_group;
    do
        vtmp_groups[$vtmp_i]=$vtmp_group
        ((vtmp_i+=1))
        echo " $vtmp_i ) $vtmp_group"
    done <<< "$vtmp_filter" # here-string

    if [ "$vtmp_i" == "0" ]
    then
    merr "No existen usuarios disponibles, cree un usuario y reinicie la ejecución" && menu && exit
    fi

    vtmp_sel=$(request -m "Introduzca el número de grupo")

    while [ "$vtmp_sel" -lt "1" ] || [ "$vtmp_sel" -gt "$vtmp_i" ];
    do
        merr "Opción inválida..." --no-break
        vtmp_sel=$(request -m "Introduzca el número de grupo")
    done

    eval $1="${vtmp_groups[$((vtmp_sel-1))]}"
}
