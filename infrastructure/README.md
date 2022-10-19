# Description

#### The entire infrastructure is set up with the case.sh script. Once the installation is complete, you can manage the kubernetes cluster from your host machine.

# Test Environment

#### Single 22.04 Ubuntu Server hosted on VMware

#### 8 cpu

#### 16 GB ram

#### 50 GB Disk

#### The estimated time for the case.sh script to complete is 25 minutes.

# Prerequisite

#### If you have hosted your base machine on VMware,Virtualbox etc. you have to open nested-virtualization on machine settings.


#### You have to be execute to [case.sh](https://github.com/devk8sops/case/blob/master/infrastructure/case.sh) as a root !


#### You can prefer to `192.168.0.0` as a private ip block on your host machine to avoid IP conflict.



# QUICK START

```

sudo -i

git clone https://github.com/devk8sops/case.git

cd case/infrastructure

./case.sh

```
