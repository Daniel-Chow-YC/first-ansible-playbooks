Automating a NodeDev Environment and MongoDB Environment using Ansible

- Set up an ansible control server (acs) as ansible cannot run on windows.
  - Configure a VM that runs on ubuntu/xenial64 for the acs where you will run ansible
- On the acs download ansible:
  - ``vagrant ssh acs``
  - Inside the VM run:
   ````
   sudo apt update
   sudo apt install software-properties-common
   sudo apt-add-repository --yes --update ppa:ansible/ansible
   sudo apt install ansible -y
   ````

- Create a basic inventory:
  - edit /etc/ansible/hosts and add your remote systems to it.
  - Do this by adding ip addresses
  - ``sudo nano /etc/ansible/hosts``
````
app ansible_ssh_host=192.168.10.100 ansible_ssh_user=vagrant ansible_ssh_pass=vagrant
db ansible_ssh_host=192.168.10.150 ansible_ssh_user=vagrant ansible_ssh_pass=vagrant

[appservers]
app
[dbservers]
db
````
To establish SSH connections:
- Try: ``ansible all -m ping -k `` else try:
- On acs create public/private key: ``ssh-keygen``
- Copy the public key:
  - ``cd .ssh``
  - ``cat id_rsa.pub`` and copy the public key
- vagrant ssh into other VMs
  - ``cd .ssh``
  - ``sudo nano authorized_keys`` and copy the public key into this file
- This should allow you to ssh into the VMs from acs
- Try: `` ansible all -m ping `` to check connection
- If this fails then ssh into the other VMs first as this will add the hosts fingerprints to the known hosts file then try again:
  - ``ssh vagrant@<the ip address> ``

Create a playbooks as a yaml file:
- `` cd ~ ``
- `` nano app.yaml ``

In this yaml file paste:
````
---
- hosts: appservers
  become: true

  tasks:
  - name: Update and upgrade apt packages
    become: true
    apt:
      upgrade: yes
      update_cache: yes

  - name: install nginx
    apt: name=nginx state=present

  - name: install git
    apt: name=git state=present

  - name: install python-software-properties
    apt: name=python-software-properties state=present

  - name: using curl to run bash command to install nodesource repo
    shell: curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -

  - name: Install NodeJS
    become: yes
    apt:
      name: nodejs
      state: present
      update_cache: yes

  - name: install pm2
    npm:
      name: pm2
      global: yes

````
or

````
---
- hosts: appservers
  become: true

  tasks:
  - name: Update and upgrade apt packages
    become: true
    apt:
      upgrade: yes
      update_cache: yes

  - name: install nginx
    apt: name=nginx state=present

  - name: install git
    apt: name=git state=present

  - name: Add Nodesource Keys
    become: yes
    apt_key:
      url: https://deb.nodesource.com/gpgkey/nodesource.gpg.key
      state: present

  - name: Add Nodesource Apt Sources
    become: yes
    apt_repository:
      repo: '{{ item }}'
      state: present
    with_items:
      - 'deb https://deb.nodesource.com/node_6.x xenial main'
      - 'deb-src https://deb.nodesource.com/node_6.x xenial main'

  - name: Install NodeJS
    become: yes
    apt:
      name: nodejs
      state: latest
      update_cache: yes

  - name: install pm2
    npm:
      name: pm2
      global: yes
````
Create a playbook for the db
`` nano db.yaml ``

````
---
- hosts: dbservers
  become: true

  tasks:

  - name: Import the public key used by the package management system
    apt_key: keyserver=hkp://keyserver.ubuntu.com:80 id=7F0CEB10 state=present
  - name: Add MongoDB repository
    apt_repository: repo='deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse' state=present
  - name: super-ugly hack to allow unauthenticated packages to install
    copy: content='APT::Get::AllowUnauthenticated "true";' dest=/etc/apt/apt.conf.d/99temp owner=root group=root mode=0644
  - name: install mongodb
    apt: pkg=mongodb-org state=latest update_cache=yes
    notify:
    - start mongodb
  - name: Remove mongod.conf file (delete file)
    file:
      path: /etc/mongod.conf
      state: absent
  - name: Create a symbolic link
    file:
      src: /home/ubuntu/environment/mongod.conf
      dest: /etc/mongod.conf
      state: link
    notify:
    - restart mongodb
  - name: enable service mongod
    systemd:
      name: mongod
      enabled: yes

  handlers:
    - name: start mongodb
      service: name=mongod state=started
    - name: restart mongodb
      service: name=mongod state=restarted
````
To run the playbooks: ``ansible-playbook app.yaml `` and ``ansible-playbook db.yaml``
