#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import getpass
from fabric.api import env, local, run, sudo, hide

env.program = "ansible-playbook"

# --------- Parte Privada ----------


def _basico():
    with hide("running"):
        local("%(program)s --inventory-file=ansible/inventory.yml --private-key=%(key_filename)s ansible/basico.yml --extra-vars 'target=%(host_string)s namehost=%(namehost)s user=%(user)s ansible_become_pass=%(password)s'" % env)


def _otros():
    with hide("running"):
        local("%(program)s --inventory-file=ansible/inventory.yml --private-key=%(key_filename)s ansible/otros.yml --extra-vars 'target=%(host_string)s user=%(user)s'" % env)


def _restart():
    with hide("running"):
        local("%(program)s --inventory-file=ansible/inventory.yml --private-key=%(key_filename)s ansible/restart.yml --extra-vars 'target=%(host_string)s user=%(user)s ansible_become_pass=%(password)s'" % env)


def _nextcloud():
    with hide("running"):
        local("%(program)s --inventory-file=ansible/inventory.yml --private-key=%(key_filename)s ansible/nextcloud.yml --extra-vars 'target=%(host_string)s user=%(user)s'" % env)


def _repositorio():
    with hide("running"):
        local("%(program)s --inventory-file=ansible/inventory.yml --private-key=%(key_filename)s ansible/repositorio.yml --extra-vars 'target=%(host_string)s user=%(user)s'" % env)


def _webmin():
    with hide("running"):
        local("%(program)s --inventory-file=ansible/inventory.yml --private-key=%(key_filename)s ansible/webmin.yml --extra-vars 'target=%(host_string)s user=%(user)s'" % env)


def _entorno_grafico():
    with hide("running"):
        local("%(program)s --inventory-file=../ansible/inventory.yml --private-key=%(key_filename)s ansible/entorno_grafico.yml --extra-vars 'target=%(host_string)s, user=%(user)s ansible_become_pass=%(password)s'" % env)


def _test_vars():
    print ("\n\tVariable Usuario: %(user)s" % env)
    print ("\tVariable Host: %(host_string)s" % env)
    print ("\tVariable NameHost: %(namehost)s" % env)
    print ("\tVariable Contrasena: %(password)s" % env)
    print ("\tVariable fichero llave: %(key_filename)s \n" % env)


def _pre_despliegue():
	with hide("running"):
		local("sed '/%(host_string)s/d' ~/.ssh/known_hosts > ~/.ssh/known_hosts.tmp" % env)
		local('mv -f ~/.ssh/known_hosts.tmp ~/.ssh/known_hosts')
		local("ssh-keygen -q -b 4096 -t rsa -f %(key_filename)s -C 'pass for %(host_string)s' -P ''" % env)
		local("sshpass -p '%(password)s' ssh-copy-id -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i %(key_filename)s %(user)s@%(host_string)s" % env)


def _post_despliegue():
    # with hide("running"):
    local("rm -f %(key_filename)s*" % env)
    #run("sshpass -p '%(password)s' passwd root" % env)
    # asegurate que la contraseña del administrador es la correcta
    local("sshpass -p '%(password)s' ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa %(user)s@%(host_string)s" % env)
    # tienes que eliminar el ficehro de la clave que has copiado
    # tienes que setear la contraseya de ROOT real


def _get_data():
    env.host_string = raw_input(
        "Por favor introduzca la IP de al maquina a desplegar:")
    env.namehost = raw_input("Por favor introduzca el nombre del Host:")
    env.user = raw_input("Por favor introduzca el usuario:")
    env.password = getpass.getpass(
        "Por favor introduzca contraseña del usuario:")
    env.key_filename = "~/.ssh/id_rsa_%(host_string)s" % env

# -------- Parte Publica -------------


def despliegue():
    _get_data()
    _test_vars()
    _pre_despliegue()
    # Cuidado con el orden en el que se ejecutan las funciones
    _basico()
    _webmin()
    _post_despliegue()


def nextcloud():
	_get_data()
	env.imput = raw_input(r"¿Desea realizar el despliegue de la maquina completa? [C], o por el contrario ¿solamente la parte del servicio seleccionado? [N]")
	_pre_despliegue()
	if env.imput == "C" or env.imput == "c":
		_basico()
        env.imput = raw_input(r"¿Desea instalar Webmin? [s/n]")
        if env.imput == "S" or env.imput == "s":
        	_webmin()
	elif env.imput == "N" or env.imput == "n":
		_nextcloud()
	else:
		print ("\n\tNo se ha elegido el método para instalar")
	_post_despliegue()


def repositorio():
    # Tienes que cambiar los permisos de la carpeta datos, con el usuario admin y el grupo root ponerlo en el script de el repositorio,
    # bien desde la plantilla de ansible o bien desde fabric, para poder llegar ha este punto es necesario generar el usuario antes de asignar
	_get_data()
	env.imput = raw_input(r"¿Desea realizar el despliegue de la maquina completa? [C], o por el contrario ¿solamente la parte del servicio seleccionado? [R]")
	_pre_despliegue()
	if env.imput == "C" or env.imput == "c":
		_basico()
		env.imput = raw_input(r"¿Desea instalar Webmin? [s/n]")
		if env.imput == "S" or env.imput == "s":
			_webmin()
	elif env.imput == "R" or env.imput == "r":
		_repositorio()
	else:
		print ("\n\tNo se ha elegido el método para instalar")
	_post_despliegue()
    


def restart():
	# no esta depurada esta funcionalidad
	env.host_string = raw_input("Por favor introduzca la IP de al maquina a reiniciar:")
	env.user = raw_input("Por favor introduzca el usuario:")
	env.password = getpass.getpass("Por favor introduzca contraseña del usuario:")
	local("sed '/%(host_string)s/d' ~/.ssh/known_hosts > ~/.ssh/known_hosts.tmp" % env)
	local('mv -f ~/.ssh/known_hosts.tmp ~/.ssh/known_hosts')
	run('shutdown -r 0')
	#_restart()


def upgrade_version():
	_get_data()
	env.host_string = raw_input("Por favor introduzca la IP de al maquina a reiniciar:")
	env.version = raw_input("Indique el número de versión de Fedora a la que quiere actualizar:")
	run('dnf upgrade --refresh')
	run('dnf install dnf-plugin-system-upgrade')
	run('dnf system-upgrade download --releasever=%(version)s' % env)
	run('dnf system-upgrade reboot')


def ayuda():
    print ("\n\tEjemplos:")
    print ("\n\tDespliegue simple:")
    print ("\t fab despliegue")
    print ("\n\tDespliegue Repositorio:")
    print ("\t fab repositorio")
    print ("\n\tPara poder realizar el despliegue es necesario ejecutar en este orden los comandos:")
    print ("\t despliegue")
    print ("\t repositorio")
