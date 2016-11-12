#!/bin/bash
# Titulo:	Preparar entorno para trabajar con optirun, plasmashell y compiz
# Fecha:	12/11/16
# Autor:	elsudano
# Versión:	1.0
# Descripción:	Se reinician diferentes servicios, y se cierran aplicaciones que estan en el arranque del sistema
# para que se puedan volver a arrancar cuando esta la gráfica dedicada encendida
# Opciones: Ninguna
# Uso: ./optirun-compiz-plasmashell [start|stop]
#------------------------------------------------------------Cabeceras de Configuración------------------------------------------------------------------------------------------------------------
BINARIOS=(optirun bumblebeed killall fusion-icon compiz)
# optirun	  aplicación que se usa para asignar los programas a la grafica dedicada se instala con bumblebee
# bumblebeed  este es un demonio que se usa para arrancar la gráfica dedicada
# killall     Para detener todas las instancias de un programa que ya esta iniciado
# compiz      Gestor de escritorio desarrollado de forma mas optima
# fusion-icon applet para gestionar compiz

#----------------------------------------Función de Error------------------------------------------------
# Funcion que me permite escribir en la consola de error
function echoerr() { echo "$@" >&2; }

#---------------------------------------------Función Comprobar Ficheros-------------------------------------------------
function comprobar(){
for fichero in ${BINARIOS[@]}
do
	local df=($(find /bin/ /usr/sbin/ -name $fichero)) # variable df = directorios de ficheros
	local let C=0;
	local retval=1;
	if [[ ${#df[@]} -gt "0" ]]; then
		while [  $retval != 0 ]; do
			if [ -x ${df[C]} ]; then
				retval=0;
			fi
			let C=C+1
		done
	fi
	if [[ $retval -eq 1 ]]; then
		echo $retval;
		exit;
	fi
done;
echo $retval;
}

#---------------------------------------------Función de inicio-------------------------------------------------
function start(){
    killall plasmashell;
    sleep 1;
    systemctl start bumblebeed.service;
    sleep 1;
    optirun plasmashell &;
    sleep 1;
    compiz ccp --replace --sm-disable --ignore-desktop-hints;
    fusion-icon;
}

#---------------------------------------------Función de parada-------------------------------------------------
function stop(){
    killall plasmashell;
    sleep 1;
    killall compiz;
    sleep 1;
    systemctl stop bumblebeed.service;
}

#----------------------------------------MAIN-------------------------------------------------------------------------
if [[ $1 == "--help" || $1 == "-h" || $1 == "" ]]; then
	echo;
	echo "Usage $0 [start|stop|restart]";
	#echo "and mode auto is: $0 [auton|autoff]";
	echo;
else
    if [ $(whoami) == "root" ]; then
    	if [ "$(comprobar)" == "0" ]; then
    		if [[ $1 != "" ]]; then
    			COMANDO=$1;
    		fi
    		if [[ $COMANDO == "stop" ]]; then
                stop;
                echo "plasmashell se ha cerrado, compiz también y bumblebeed se ha detenido como servicio"
    		fi
    		if [[ $COMANDO == "start" ]]; then
                start;
    			echo "Compiz, plasmashell y Gráfica dedicada iniciados"
    		fi
            if [[ $COMANDO == "restart" ]]; then
                stop;
                start;
    			echo "Programas reiniciados"
    		fi
    	else
    		echo "Falta un ejecutable"
    	fi
    else
        echo
        echo "Es necesario ser root para ejecutar esta orden"
        echo
    fi
fi
