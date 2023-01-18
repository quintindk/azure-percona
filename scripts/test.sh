#!/bin/bash -e

export server_id=1
export admin_mysql_user="dbadmin"
export admin_mysql_password="this-is-not-a-safe-secret"
export pmm_admin_password="this-is-not-a-safe-secret"
ansible-playbook -vv -T 300 /staging/scripts/ansible/percona.yaml