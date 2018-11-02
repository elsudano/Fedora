#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os, getpass
from fabric.api import env, local, run, sudo, hide

# --------- Parte Privada ----------
def _basico():
    with hide("running"):
        local("ansible-playbook --inventory-file=ansible/inventory.yml --private-key=%(key_filename)s ansible/basico.yml --extra-vars 'target=%(host)s namehost=%(namehost)s user=%(user)s ansible_become_pass=%(password)s'" % env)

def _otros():
    with hide("running"):
        local("ansible-playbook --inventory-file=ansible/inventory.yml --private-key=%(key_filename)s ansible/otros.yml --extra-vars 'target=%(host)s user=%(user)s'" % env)

def _restart():
    with hide("running"):
        local("ansible-playbook --inventory-file=ansible/inventory.yml --private-key=%(key_filename)s ansible/restart.yml --extra-vars 'target=%(host)s user=%(user)s ansible_become_pass=%(password)s'" % env)

def _nextcloud():
    with hide("running"):
        local("ansible-playbook --inventory-file=ansible/inventory.yml --private-key=%(key_filename)s ansible/nextcloud.yml --extra-vars 'target=%(host)s user=%(user)s'" % env)

def _repositorio():
    with hide("running"):
        local("ansible-playbook --inventory-file=ansible/inventory.yml --private-key=%(key_filename)s ansible/repositorio.yml --extra-vars 'target=%(host)s user=%(user)s'" % env)
    
def _webmin():
    with hide("running"):
        local("ansible-playbook --inventory-file=ansible/inventory.yml --private-key=%(key_filename)s ansible/webmin.yml --extra-vars 'target=%(host)s user=%(user)s'" % env)

def _entorno_grafico():
    with hide("running"):
        local("ansible-playbook --inventory-file=../ansible/inventory.yml --private-key=%(key_filename)s ansible/entorno_grafico.yml --extra-vars 'target=%(host)s, user=%(user)s ansible_become_pass=%(password)s'" % env)

def _test_vars():
    print ("\n\tVariable Usuario: %(user)s" % env)
    print ("\tVariable Host: %(host)s" % env)
    print ("\tVariable NameHost: %(namehost)s" % env)
    print ("\tVariable Contrasena: %(password)s" % env)
    print ("\tVariable fichero llave: %(key_filename)s \n" % env)

def _pre_despliegue():
    with hide("running"):
        local("ssh-keygen -q -b 4096 -t rsa -f %(key_filename)s -C 'pass for %(host)s' -P ''" % env)
        local("sshpass -p '%(password)s' ssh-copy-id -o StrictHostKeyChecking=no -i %(key_filename)s %(user)s@%(host)s" % env)
    
def _post_despliegue():
    #with hide("running"):
        local("rm -f %(key_filename)s*" % env)
        #run("sshpass -p '%(password)s' passwd root" % env)
        # asegurate que la contraseña del administrador es la correcta
        local("sshpass -p '%(password)s' ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa %(user)s@%(host)s" % env)
        # tienes que eliminar el ficehro de la clave que has copiado
        # tienes que setear la contraseya de ROOT real

def _get_data():
    env.host = raw_input("Por favor introduzca la IP de al maquina a desplegar:")
    env.namehost = raw_input("Por favor introduzca el nombre del Host:")
    env.user = raw_input("Por favor introduzca el usuario:")
    env.password = getpass.getpass("Por favor introduzca contraseña del usuario:")
    env.key_filename = "~/.ssh/id_rsa_%(host)s" % env

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
    _nextcloud()
    
def repositorio():
    # no esta depurada esta funcionalidad
    answer = raw_input("\¿Desea realizar el despliegue de la maquina completa\? [C], o por el contrario \¿solamente la parte del repositorio\? [R]")
    despliegue()
    _repositorio()

def restart():
    # no esta depurada esta funcionalidad
    env.host = raw_input("Por favor introduzca la IP de al maquina a reiniciar:")
    env.namehost = ""
    env.user = raw_input("Por favor introduzca el usuario:")
    env.password = getpass.getpass("Por favor introduzca contraseña del usuario:")
    env.key_filename = ""
    _test_vars()
    _restart()

def ayuda():    
    print ("\n\tEjemplos:")
    print ("\n\tDespliegue simple:")
    print ("\t fab despliegue")
    print ("\n\tDespliegue Repositorio:")
    print ("\t fab repositorio")
    print ("\n\tPara poder realizar el despliegue es necesario ejecutar en este orden los comandos:")
    print ("\t despliegue")
    print ("\t repositorio")
