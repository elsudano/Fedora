#!/bin/bash

TOKEN=""

function is_root {
  if [[ $EUID -ne 0 ]]; then
      echo " not root";
      exit;
  fi
}

function compress() {
  tar -zcvf /home/xwiki-backup.tar.gz /opt/xwiki/
  split -b 100M /home/xwiki-backup.tar.gz "/home/xwiki-backup.part"
  # para volver a juntar los ficheros 
  # cat xwiki-backup.tar.gz.parta* >xwiki-backup.tar.gz
}

function share() {
  file=$(echo $1 | cut -c7-)
  curl -X POST https://content.dropboxapi.com/2/files/upload \
    --header "Authorization: Bearer $TOKEN" \
    --header "Dropbox-API-Arg: {\"path\": \"/backup/$file\",\"mode\": \"add\",\"autorename\": true,\"mute\": false,\"strict_conflict\": false}" \
    --header "Content-Type: application/octet-stream" \
    --data-binary @$1
}

function clean {
  rm -f /home/xwiki-backup.*
  rm -f /home/*.part*
  echo > /var/log/btmp 
  echo > /var/log/wtmp 
  echo > /var/log/lastlog
  echo > ~/.bash_history
}

is_root;
compress;
for file in $( ls /home/*.part* ); do share $file; done
clean;
rm -f $0;
