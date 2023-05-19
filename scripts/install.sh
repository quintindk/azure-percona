#!/bin/bash -e

# update the repos
sudo apt-get update

# update apt-get to use python3.10
sudo apt-get upgrade -y

# install tools for ppa
sudo apt-get install software-properties-common -y

# add the python3 ppa
sudo add-apt-repository --yes --update ppa:deadsnakes/ppa

# add the ansible ppa
sudo add-apt-repository --yes --update ppa:ansible/ansible

# install python3.10, pip and ansible
sudo apt-get install libmysqlclient-dev python3-pip python3-apt-get python3-pymysql ansible --yes

# set the ansible intepreter
sudo sed -i 's|\[defaults\]|[defaults]\ninterpreter_python=/usr/bin/python3|g' /etc/ansible/ansible.cfg
ansible-galaxy collection install community.docker
ansible-galaxy collection install community.mysql
ansible-playbook -vv -T 300 "/staging/scripts/ansible/percona.yaml"
