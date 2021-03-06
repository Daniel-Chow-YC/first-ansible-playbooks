#!/bin/bash

# installing ansible on acs
sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible -y

sudo rm /etc/ansible/hosts
sudo ln -s /home/ubuntu/environment/hosts /etc/ansible/hosts
