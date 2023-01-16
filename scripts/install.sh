#!/bin/bash -e

sudo apt update
sudo apt install ansible -y
ansible-playbook -vv -T 300 percona.yaml