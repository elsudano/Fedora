#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import getpass
from fabric.api import env, local, run, sudo, hide, abort, prompt, reboot

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
    print ("\n\tVariable Host: %(host_string)s" % env)
    print ("\tVariable NameHost: %(namehost)s" % env)
    print ("\tVariable Usuario: %(user)s" % env)    
    print ("\tVariable Contrasena: %(password)s" % env)


def _pre_despliegue():
    with hide("running"):
        env.key_filename = "~/.ssh/id_rsa_%(host_string)s" % env
        env.key_gen = True
        local("sed '/%(host_string)s/d' ~/.ssh/known_hosts > ~/.ssh/known_hosts.tmp" % env)
        local('mv -f ~/.ssh/known_hosts.tmp ~/.ssh/known_hosts')
        local("ssh-keygen -q -b 4096 -t rsa -f %(key_filename)s -C 'pass for %(host_string)s' -P ''" % env)
        local("sshpass -p '%(password)s' ssh-copy-id -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i %(key_filename)s %(user)s@%(host_string)s" % env)
#        try:
#            ## Se utiliza este try para comprobar si ya hay acceso a la maquina remota. En ese caso no tenemos que generar key y usamos la que ya tiene.
#            env.pub_key = local("cat ~/.ssh/id_rsa.pub")
#            print ('%(pub_key)s'  % env)
#            abort("Saliendo de Fabric")
#            run('ls')
#            env.key_filename = "~/.ssh/id_rsa"                  #Key existente
#            env.key_gen = False
#        except Exception:
#            print ("No he podido conectarme, creando llave de conexión que se eliminará mas tarde")
#         local("ssh-keygen -q -b 4096 -t rsa -f %(key_filename)s -C 'pass for %(host_string)s' -P ''" % env)
#         local("sshpass -p '%(password)s' ssh-copy-id -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i %(key_filename)s %(user)s@%(host_string)s" % env)
#         env.key_filename = "~/.ssh/id_rsa_%(host_string)s" % env            #Key generada
#            env.key_gen = True


def _post_despliegue():
    with hide("running"):
        if env.key_gen:
            local("rm -f %(key_filename)s*" % env)
            local("sshpass -p '%(password)s' ssh-copy-id -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa %(user)s@%(host_string)s" % env)
        #run("sshpass -p '%(password)s' passwd root" % env)
        # asegurate que la contraseña del administrador es la correcta
        # tienes que setear la contraseya de ROOT real


def _get_data():
    prompt('Por favor introduzca la IP de al maquina a desplegar:', 'host_string')
    prompt('Por favor introduzca el nombre del Host:', 'namehost')
    prompt('Por favor introduzca el usuario:', 'user')
    env.password = getpass.getpass("Por favor introduzca contraseña del usuario:")
    

def _check_data():
    _test_vars()
    prompt('\tAtención! Va a realizar operaciones importantes en la máquina destino.\n\tAsegúrese de que la IP y el nombre de la máquina son los correctos\n\tpulse 'y' para continuar o 'n' para salir: (y/n)', 'warning_data')
    if env.warning_data == "Y" or env.warning_data == "y":
        abort("Saliendo de Fabric")
    elif env.warning_data == "N" or env.warning_data == "n":
        abort("Saliendo de Fabric")
    else:
        print ("\n\tOpción incorrecta")
# -------- Parte Publica -------------


def despliegue():
    _get_data()
    _test_vars()
    prompt('\tAtención! Va a realizar operaciones importantes en la máquina destino.\n\tAsegúrese de que la IP y el nombre de la máquina son los correctos\n\tpulse 'y' para continuar o 'n' para salir: (y/n)', 'warning_data')
    if env.warning_data == "Y" or env.warning_data == "y":
        _pre_despliegue()
        # Cuidado con el orden en el que se ejecutan las funciones
        _basico()
        prompt('¿Desea instalar Webmin? [s/n]'), 'imput')
        if env.imput == "S" or env.imput == "s":
        	_webmin()
        _post_despliegue()
    elif env.warning_data == "N" or env.warning_data == "n":
        abort("Saliendo de Fabric")
    else:
        print ("\n\tOpción incorrecta")
	

def nextcloud():
	_get_data()


def repositorio():
    # Tienes que cambiar los permisos de la carpeta datos, con el usuario admin y el grupo root ponerlo en el script de el repositorio,
    # bien desde la plantilla de ansible o bien desde fabric, para poder llegar ha este punto es necesario generar el usuario antes de asignar
	_get_data()


def restart():
    prompt('Por favor introduzca la IP de al maquina a desplegar:', 'host_string')
    prompt('Por favor introduzca el usuario:', 'user')
    env.password = getpass.getpass("Por favor introduzca contraseña del usuario:")
    print ("\tVariable Host: %(host_string)s" % env)
    print ("\tVariable Usuario: %(user)s" % env)
    print ("\tVariable Contrasena: %(password)s" % env)
    env.warning_data = raw_input(
        "\n\tAtención! Va a realizar operaciones importantes en la máquina destino.\n\tAsegúrese de que la IP y el nombre de la máquina son los correctos\n\tpulse 'y' para continuar o 'n' para salir: (y/n)")    
    if env.warning_data == "Y" or env.warning_data == "y":
        local("sed '/%(host_string)s/d' ~/.ssh/known_hosts > ~/.ssh/known_hosts.tmp" % env)
        local('mv -f ~/.ssh/known_hosts.tmp ~/.ssh/known_hosts')
        run('shutdown -r 0')
    elif env.warning_data == "N" or env.warning_data == "n":
        abort("Saliendo de Fabric")
    else:
        print ("\n\tOpción incorrecta")


def upgrade_version():
	_get_data()
	_check_data()
    prompt('Indique el número de versión de Fedora a la que quiere actualizar:', 'version')
	_pre_despliegue()
	sudo('dnf upgrade --refresh -y')
	sudo('dnf install dnf-plugin-system-upgrade -y')
	sudo('dnf system-upgrade download --releasever=%(version)s -y' % env)
	sudo('dnf system-upgrade reboot')


def ayuda():
    print ("\n\tEjemplos:")
    print ("\n\tDespliegue simple:")
    print ("\t fab despliegue")
    print ("\n\tDespliegue Repositorio:")
    print ("\t fab repositorio")
    print ("\n\tPara poder realizar el despliegue es necesario ejecutar en este orden los comandos:")
    print ("\t despliegue")
    print ("\t repositorio")
