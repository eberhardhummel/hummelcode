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
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  apt-cache madison docker-ce
  sudo apt-get update
  sudo apt-get install -y containerd.io
  sudo service docker start
  sudo apt-get install kubernetes
  docker ps -a
  sudo swapoff -a
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  sudo bash -c 'echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list'
  sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl
  sudo systemctl enable kubelet
  sudo systemctl start kubelet
  kubeadm join master:6443 --token 54imxs.qj3cjf5wdz0c5xnr 	--discovery-token-ca-cert-hash sha256:0e4dd6334ed96c27ac72a7320b4f06dbaa7f780fe01ac4c50e34044a6c735d61
  kubectl delete node kube-slave
  kubectl drain kube-master --ignore-daemonsets --delete-local-data
  kubectl drain kube-slave --ignore-daemonsets --delete-local-data
  kubectl drain kube-worker --ignore-daemonsets --delete-local-data
  kubectl cluster info
  kubectl cluster-info
  kubectl cluster-info dump
  sudo cp daemon.json /etc/docker/daemon.json
  sudo systemctl restart docker
  docker info
  sudo kubeadm reset
  sudo systemctl enable kubelet
  sudo systemctl start kubelet

  #grep the following command from the master node deploy script
  #kubeadm join master:6443 --token oefhp7.js7ggsgvm1c8sadr 	--discovery-token-ca-cert-hash sha256:cde6e1350c21510b712699d4fd4c73bfbc77da8d120694fbc8bbe8a1d34790be 
  sshpass -p $(cat .password) scp root@master:/root/kubeadmin-init.log .
  tail -n 2 kubeadmin-init.log > kubeadmin-worker-join.sh
  chmod a+x kubeadmin-worker-join.sh
  ./kubeadmin-worker-join.sh
}

#teardown
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
  #sudo apt-get -y remove golang
  #sudo apt-get -y remove libvirt
  sudo apt -y autoremove
  sudo rm -rf /etc/kubernetes/*
  sudo rm -rf /var/lib/docker/*
  sudo rm -rf /root/.kube/*
  sudo rm -rf /var/lib/etcd/*
  sudo rm -rd /var/lib/kubelet/*
  #umount /var/lib/kubelet/pods/c7a19188-69b0-4014-adb4-788559ce5b1f/volumes/kubernetes.io~projected/kube-api-access-cf2vs
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

