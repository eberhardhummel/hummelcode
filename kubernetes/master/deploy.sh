#/bin/bash
#ubuntu 21.04
#sudo apt-get install ssh
#sudo vi /etc/ssh/sshd_config
#add nopasswd
#service ssh restart

#build up
function buildup {

  echo "Start build up"
  #sudo apt-get update
  #sudo apt-get install -y golang
  
  #sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys 7EA0A9C3F273FCD8
  
  sudo curl -LR https://download.docker.com/linux/ubuntu/gpg -o ./docker.gpg
  #Verify the type of file
  file ./docker.gpg
  #it should be PGP public key block Public-Key (old)
  #Create a keyring
  gpg --no-default-keyring --keyring ./docker-keyring.gpg --import ./docker.gpg
  #This file is still not a valid key that can be added to /etc/apt/trusted.gpg.d/ since it's a keyring, but from the keyring we can extract the key with
  gpg --no-default-keyring --keyring ./docker-keyring.gpg --export > ./docker-asc.gpg
  #This file is the key you want to move to the trusted key folder
  sudo cp ./docker-asc.gpg /etc/apt/trusted.gpg.d/docker.gpg.asc
  
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common
  #curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu hirsute stable"

  #sudo apt-cache madison docker-ce
  echo "running sudo apt-get install -y docker.io"
  sudo apt-get install -y docker.io 
  
  echo "sleeping for 30 seconds to let docker finish installing"
  sleep 30
  sudo cp daemon.json /etc/docker/daemon.json
  echo "stopping docker service"
  systemctl stop docker
  sudo service docker stop
  sleep 10
  echo "starting docker service"
  sudo service docker start
  #sudo service docker status
  sleep 10
  docker info
  docker ps -a
  docker images
  exit 0
  sudo swapoff -a
  sudo ufw disable
  sudo apt-get update
  #curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  #sudo bash -c 'echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list'
  sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
  echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  sudo apt-get update 
  sudo apt-get install -y kubectl
  
  
  sudo apt-get install -y kubernetes
  sudo apt-get install -y kubeadm
  sudo systemctl enable kubelet
  sudo systemctl start kubelet
  echo "sleeping for 45 seconds to let kublet finish starting"
  sleep 45
  ipaddress=$(ip -f inet addr show ens33 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p')
  echo "ipaddress is: " $ipaddress
  
  sudo kubeadm init --apiserver-advertise-address=$ipaddress | tee /root/kubeadmin-init.log
  echo "finished kubeadm init"
  
  #export KUBECONFIG=/etc/kubernetes/admin.conf
  cp /etc/kubernetes/admin.conf ~/.kube/config
  
  #install weave networking
  echo "installing weave networking..."
  kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
  
  exit 0
  
  #install flannel networking
  #wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  
  #install dashboard
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml
  kubectl apply -f kubernetes-dashboard-anonymous.yaml
  kubectl create -f ./create-namespace.yaml
  kubectl apply -f hello-world-container-deployment.yaml
  kubectl apply -f deploy-pod.yaml
  kubectl rollout restart deployment kube-master
  sleep 60 
  kubectl cluster-info
  kubectl get namespaces
  kubectl get pods --all-namespaces
  kubectl get nodes --all-namespaces
  kubectl describe node kube-master
  kubectl get services --all-namespaces
  kubectl get deployments --all-namespaces
  lsof -i -P -n | grep 8080
}

function teardown {
  echo "start tear down"
  kubectl delete clusterrolebinding kubernetes-dashboard-anonymous
  kubectl drain kube-master --ignore-daemonsets --delete-emptydir-data
  systemctl stop kubelet
  kubectl delete node kube-master
  kubectl delete node kube-slave
  kubectl -n kubernetes-dashboard delete pod,svc --all
  kubectl -n kube-system delete pod,svc --all
  sudo apt-get -y remove kubelet
  sudo apt-get -y remove kubernetes-cni
  sudo apt-get -y remove kubectl
  sudo apt-get -y remove kubernetes
  sudo apt-get -y remove kubeadm
  sudo apt-get -y remove docker-ce
  sudo apt-get -y remove docker.io
  #sudo apt-get -y remove golang
  #sudo apt-get -y remove libvirt
  sudo apt -y autoremove
  sudo rm -rf /etc/kubernetes
  sudo rm -rf /var/lib/docker
  sudo rm -rf /etc/docker
  sudo rm -f /etc/init.d/docker
  sudo rm -f /etc/default/docker
  sudo rm -f /usr/bin/docker
  sudo rm -rf /run/docker*
  sudo rm -f /etc/apt/trusted.gpg.d/docker.gpg.asc
  sudo rm -rf /root/.kube/*
  sudo rm -rf /var/lib/etcd/*
  sudo rm -rd /var/lib/kubelet/*
  sudo rm -f /etc/systemd/system/kubelet.service
  sudo rm -f /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  #sudo umount /var/lib/kubelet/pods/*
  rm -r /tmp/umount.txt
  mount -l | grep "/var/lib/kubelet/pods/" > /tmp/umount.txt
  #sed 's^tmpfs on ^^g' |  sed 's^ tmpfs (rw,relatime,inode64)^^g' | /tmp/umount.txt
  sed 's^tmpfs on ^umount ^g; s^ type tmpfs (rw,relatime,inode64)^^g' /tmp/umount.txt > kubmounts.txt
  source ./kubmounts.txt
  echo "list of mounts is: " $(mount -l)
}

if [ -z "$1" ]
then
  echo "missing parameter buildup or teardown"
  exit 1
fi

case $1 in
  buildup)
    buildup
    exit 0
    ;;
  teardown)
    teardown
    exit 0
    ;;
  *)
    echo "invalid parameter, exit"
    exit 1
    ;;
esac



