#/bin/bash
#ubuntu 21.04

#service ssh restart
#set hostname to kube-slave - hostnamectl, /etc/hosts, /etc/hostname
#vi /etc/sudoers
#sudo apt-get install net-tools ssh
#sudo vi /etc/ssh/sshd_config
#sudo service ssh restart
#sudo apt purge snapd
#sudo snap remove snap-store

#build up
function buildup {
  echo "Start build up"
  echo   "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get install -y sshpass
  sudo apt-get install -y curl
  url -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  sudo apt-get update
  sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys 7EA0A9C3F273FCD8
  sudo apt-get update
  sudo apt-get install -y     apt-transport-https     ca-certificates     curl     gnupg     lsb-release
  sudo apt-get install -y docker-ce
  sudo cp daemon.json /etc/docker/daemon.json
  #sudo systemctl restart docker
  echo "sleeping for 60 seconds to let docker finish installing"
  sleep 60
  echo "stopping docker service"
  systemctl stop docker
  echo "starting docker service"
  systemctl start docker
  docker ps -a
  sudo swapoff -a
  sudo ufw disable
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  sudo bash -c 'echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list'
  sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl
  sudo systemctl enable kubelet
  sudo systemctl start kubelet
  echo "sleeping for 60 seconds to let kubelet finish installing"
  sleep 60
  sshpass -p $(cat .password) scp root@master:/root/kubeadmin-init.log .
  tail -n 2 kubeadmin-init.log > kubeadmin-worker-join.sh
  echo "kubeadmin-worker-join.sh is: " 
  cat kubeadmin-worker-join.sh
  chmod a+x kubeadmin-worker-join.sh
  ./kubeadmin-worker-join.sh
  kubectl cluster-info
  kubectl cluster-info dump
  docker info
}

#teardown
function teardown {
  echo "start tear down"
  kubectl drain kube-slave --ignore-daemonsets --delete-emptydir-data
  kubectl delete node kube-slave
  kubectl drain kube-worker --ignore-daemonsets --delete-local-data
  kubectl delete node kube-worker
  kubectl cluster info
  systemctl stop kubelet
  kubectl delete node kube-slave
  kubectl -n kubernetes-dashboard delete pod,svc --all
  kubectl -n kube-system delete pod,svc --all
  sudo apt-get -y remove kubelet
  sudo apt-get -y remove kubernetes-cni
  sudo apt-get -y remove kubectl
  sudo apt-get -y remove kubernetes
  sudo apt-get -y remove kubeadm
  sudo apt-get -y remove docker-ce
  #sudo apt-get -y remove golang
  sudo apt -y autoremove
  sudo rm -rf /etc/kubernetes/*
  sudo rm -rf /var/lib/docker/*
  sudo rm -rf /root/.kube/*
  sudo rm -rf /var/lib/etcd/*
  sudo rm -rd /var/lib/kubelet/*
  rm -r /tmp/umount.txt
  mount -l | grep "/var/lib/kubelet/pods/" > /tmp/umount.txt
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

