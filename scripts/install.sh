#!/bin/bash -e

# update the repos
sudo apt update

# update apt to use python3.10
sudo apt upgrade -y

# install tools for ppa
sudo apt install software-properties-common

# add the python3 ppa
sudo add-apt-repository --yes --update ppa:deadsnakes/ppa

# add the ansible ppa
sudo add-apt-repository --yes --update ppa:ansible/ansible

# install python3.10, pip and ansible
sudo apt install libmysqlclient-dev python3.10 python3-pip python3-pymysql ansible --yes

# set python3 to 3.10
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

# set the ansible intepreter
sudo sed -i 's|\[defaults\]|[defaults]\ninterpreter_python=/usr/bin/python3|g' /etc/ansible/ansible.cfg
ansible-galaxy collection install community.docker
ansible-galaxy collection install community.mysql
ansible-playbook -vv -T 300 "/staging/scripts/ansible/percona.yaml"
