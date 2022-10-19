#!/bin/bash

apt update -y

echo "KVM Nested Virtuluzation Check"
#############KVM Nested Virtuluzation Check 

apt install cpu-checker -y

KVM=$(kvm-ok | awk 'NR==2{print}')


VAR="KVM acceleration can be used"

if [ "$KVM" = "$VAR" ] ; then
  echo  "KVM is ok."
else
  echo "KVM acceleration can Not be used"
  exit 1
fi

echo "Virtualbox Installation"
#############Virtualbox Installation

apt install virtualbox -y


echo  "Vagrant Installation"
############Vagrant Installation

apt install vagrant -y

mkdir -p /etc/vbox/

echo "* 0.0.0.0/0 ::/0" > /etc/vbox/networks.conf


if

[ -f "/usr/local/bin/terraform" ]; then

echo "Terraform already installed."

else

echo  "Terraform Installation"
############Terraform Installation

apt-get install unzip

wget https://releases.hashicorp.com/terraform/1.3.2/terraform_1.3.2_linux_amd64.zip

unzip terraform_1.3.2_linux_amd64.zip

sudo mv terraform /usr/local/bin/

sleep 5s

rm terraform_1.3.2_linux_amd64.zip

terraform --version

fi

echo  "Terraform apply section"
############Terraform apply section

cd terraform-vagrant

terraform init

terraform apply -auto-approve

cd ../kubernetes-vagrant

vagrant status

sleep 5

echo  "Kubectl Installation"
###########Kubectl Installation

apt-get update

sleep 3

apt-get install -y ca-certificates curl

apt-get install -y apt-transport-https

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

apt-get install -y kubectl

echo  "Set up kubeconfig for host"
###########Set up kubeconfig for host

mkdir -p $HOME/.kube

cp configs/config $HOME/.kube

cd ..

if

[ -f "/usr/local/bin/helm" ]; then

echo "Helm already installed."

else

echo  "Helm Installation"
###########Helm Installation


wget https://get.helm.sh/helm-v3.9.3-linux-amd64.tar.gz

tar xvf helm-v3.9.3-linux-amd64.tar.gz

sleep 3s

mv linux-amd64/helm /usr/local/bin

sleep 3s

rm helm-v3.9.3-linux-amd64.tar.gz

rm -rf linux-amd64

helm version

fi

echo  "Ingress Installation"
###########Ingress Installation

kubectl apply -f  ingress/deploy.yaml

until [ \
  "$(curl -o /dev/null --silent --head -k --write-out '%{http_code}\n' https://10.0.0.10:30443/healthz)" \
  -eq 200 ]
do
  echo 'Waiting for ingress to be ready..'
  sleep 20
done



ip4=$(hostname -I | awk '{print $1}')

is_haproxy_exists=$(which haproxy)

if [[ $? == 0 ]]; then

echo "Haproxy already installed."

else

echo  "HaProxy Installation"
###########HaProxy Installation

apt install haproxy -y

openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout /etc/haproxy/ca.key -out /etc/haproxy/ca.crt -subj "/CN=test.com"

touch /etc/haproxy/ca.pem
cat /etc/haproxy/ca.crt >> /etc/haproxy/ca.pem
cat /etc/haproxy/ca.key >> /etc/haproxy/ca.pem




cat >> /etc/haproxy/haproxy.cfg  <<EOF

frontend front_nginx_ingress_controller
  bind $ip4:80
  bind $ip4:443 ssl crt /etc/haproxy/ca.pem
  http-request redirect scheme https unless { ssl_fc }
  default_backend nginx_ingress_controller_service
backend nginx_ingress_controller_service
  balance roundrobin
  server k8s-node1 10.0.0.10:30443 ssl check port 30443 verify none
  server k8s-node2 10.0.0.11:30443 ssl check port 30443 verify none

EOF

systemctl restart haproxy


fi



if

[ -d "/mnt/nfs_share" ]; then

echo "NFS-server already installed."

else

echo "NFS Server Installation"
#############NFS Server Installation

apt update -y

apt install nfs-kernel-server -y

mkdir -p /mnt/nfs_share

chown -R nobody:nogroup /mnt/nfs_share/

chmod 777 /mnt/nfs_share/

cat >> /etc/exports << EOF 

/mnt/nfs_share  *(rw,sync,no_root_squash,insecure)

EOF

exportfs -a

systemctl restart nfs-kernel-server



fi

#############Kubernetes master-node delete taint

kubectl taint nodes master-node node-role.kubernetes.io/master:NoSchedule-

#############NFS server entegration with Kubernetes


helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner

helm upgrade --install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --create-namespace --namespace nfs  \
              --set nfs.server=$ip4 --set nfs.path=/mnt/nfs_share 



kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'


############IP arrange for ingress.yaml


#sed -i "s/ankara/$ip4.nip.io/g" kubernetes/helm/gitlab/values.yaml

sed -i "s/ankara/jenkins.$ip4.nip.io/g" kubernetes/helm/jenkins/values.yaml

sed -i "s/ankara/pgadmin.$ip4.nip.io/g" kubernetes/helm/pgadmin/values.yaml



############Gitlab Installation >>>> Cancelled for resource requirements.

#kubectl create ns gitlab

#kubectl create secret generic gitlab-gitlab-initial-root-password --from-literal=password="admin123" -n gitlab

#helm repo add gitlab https://charts.gitlab.io/

#helm install gitlab -f kubernetes/helm/gitlab/values.yaml gitlab/gitlab --namespace gitlab --timeout 600s --set global.initialRootPassword.secret=gitlab-gitlab-initial-root-password





echo 'Jenkins Installation'
#############Jenkins Installation

helm repo add jenkins https://charts.jenkins.io

helm upgrade --install jenkins -f kubernetes/helm/jenkins/values.yaml --create-namespace --namespace jenkins jenkins/jenkins


until [ \
  "$(curl -o /dev/null --silent --head -k --write-out '%{http_code}\n' https://jenkins.$ip4.nip.io/login?from=%2F)" \
  -eq 200 ]
do
  echo 'Waiting for jenkins to be ready..'
  sleep 30
done




echo 'PGAdmin Installation'
############PGAdmin Installation

helm repo add runix https://helm.runix.net

helm upgrade --install pgadmin -f kubernetes/helm/pgadmin/values.yaml --create-namespace --namespace postgres  runix/pgadmin4


echo 'Apply postgre-backup secret'

kubectl apply -f kubernetes/postgres-backup/pgpass-secret.yaml


echo 'Redis Insight Installation'
############Redis Insight Installation

apt-get install ca-certificates curl gnupg lsb-release -y

mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y

apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

cp -rp /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/

docker-compose -f kubernetes/docker/redisinsight/docker-compose.yaml up -d


















