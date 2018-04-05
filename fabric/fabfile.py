import os
from fabric.api import env, local, run, sudo, hide

def _basico():
    #with hide('running'):
    local('ansible-playbook --inventory-file=../ansible/inventory.yml --private-key=%(key_filename)s ../ansible/basico.yml --extra-vars "target=%(host)s ansible_become_pass=%(password)s"' % env)
    local('ansible-playbook --inventory-file=../ansible/inventory.yml --private-key=%(key_filename)s ../ansible/otros.yml --extra-vars "target=%(host)s"' % env)

def _entorno_grafico():
    with hide('running'):
        local('ansible-playbook --inventory-file=../ansible/inventory.yml --private-key=%(key_filename)s ../ansible/entorno_grafico.yml --extra-vars "target=%(host)s, ansible_become_pass=%(password)s"' % env)

def _test_vars():
    print ('Variable Usuario: %(user)s\n\
Variable Host: %(host)s\n\
Variable Contrasena: %(password)s\n\
Variable fichero llave: %(key_filename)s\n\
' % env)

def _pre_despliegue():
    print ('Pre-Despliegue: %(host)s, password: %(password)s' % env)
    with hide('running'):
        local('ssh-keygen -b 4096 -t rsa -f %(key_filename)s -C "pass for %(host)s" -P ""' % env)
        local('sshpass -p %(password)s ssh-copy-id -i %(key_filename)s %(user)s@%(host)s' % env)
        #run('passwd root' % env)

def despliegue(target='',password=''):
    env.user = 'usuario'
    env.host = target
    env.password = password #aqui tienes que poner la contrasena del root remoto
    env.key_filename = '~/.ssh/id_rsa_%s' % target
    _pre_despliegue()
    #_test_vars()
    _basico()
    _entorno_grafico()
    _post_despliegue()

def _post_despliegue():
    #print ('Post-Despliegue: %(host)s, password: %(password)s' % env)
    with hide('running'):
        #run('sed "/%s/d" ~/.ssh/authorized_keys > ~/.ssh/authorized_keys')
        local('rm -f %(key_filename)s*' % env)
# tienes que eliminar el ficehro de la clave que has copiado
# tienes que copiar el fichero real de clave que usas siempre con contrasena
# tienes que setear la contraseya de ROOT real

def ayuda():
    print "\n\tEsta es la lista de comandos disponibles\n"
    with hide('running'):
        local('fab -l')
    print "\n\tEjemplos:\n\
\t fab despliegue:target=192.168.*.*,password=contrasenya ---> La IP tiene que estar en el inventario de ansible"
    print "\n\tPara poder realizar el despliegue es necesario ejecutar en este\n\
\torden los comandos:"
    #print "You said %s" % somethin
