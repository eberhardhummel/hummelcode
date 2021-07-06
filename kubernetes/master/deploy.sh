#/bin/bash
#ubuntu 21.04
#sudo apt-get install ssh
#sudo vi /etc/ssh/sshd_config
#add nopasswd
#service ssh restart

#build up
function buildup {

  echo "running the buildup loop..."
  total_runs=0
  total_succcesses=0
  total_failures=0
  while true; do
    sleep 10
    echo "**********************************************************"
    echo "**********************************************************"
    echo "**********************************************************"
    echo "**********************************************************"
    echo "**********************************************************"
    echo "performing the :" $total_runs " buildup ( succ: " $total_succcesses " fail: " $total_failures " )"
    echo "**********************************************************"
    echo "**********************************************************"
    echo "**********************************************************"
    echo "**********************************************************"
    echo "**********************************************************"
    total_runs=$((total_runs+1))
  
    echo "Start build up"
    #sudo apt-get update
    #sudo apt-get install -y golang
  
    #sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys 7EA0A9C3F273FCD8
  
    #sudo curl -LR https://download.docker.com/linux/ubuntu/gpg -o ./docker.gpg
    #file ./docker.gpg
    #gpg --no-default-keyring --keyring ./docker-keyring.gpg --import ./docker.gpg
    #gpg --no-default-keyring --keyring ./docker-keyring.gpg --export > ./docker-asc.gpg
    #sudo cp ./docker-asc.gpg /etc/apt/trusted.gpg.d/docker.gpg.asc
  
    #sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common
    #curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu hirsute stable"
    sudo apt-get update
  
    echo "running sudo apt-get install -y docker.io"
    sudo apt-get install -y docker.io
    sleep 5
    service docker start
    sleep 5
    docker ps -a
    service docker stop
    echo "sleeping for 30 seconds..."
    sleep 30
    sudo mkdir /etc/docker
    sudo cp ./daemon.json /etc/docker/daemon.json
    echo "starting docker service"
    service docker start
    sleep 30
    docker info
    docker ps -a
    sudo docker images | tee /tmp/docker_images.out
  
    if (cat /tmp/docker_images.out | grep "REPOSITORY   TAG       IMAGE ID   CREATED   SIZE"); then
      total_succcesses=$((total_succcesses+1))
      echo "**********************************************************"
      echo "**********************************************************"
      echo "**********************************************************"
      echo "**********************************************************"
      echo "**********************************************************"
      echo "************** docker was installed successfully " $total_succcesses " times **************"
      echo "**********************************************************"
      echo "**********************************************************"
      echo "**********************************************************"
      echo "**********************************************************"
      echo "**********************************************************"
      break
    else
      total_failures=$((total_failures+1))
      echo "**********************************************************"
      echo "**********************************************************"
      echo "**********************************************************"
      echo "**********************************************************"
      echo "**********************************************************"
      echo "************** docker was not properly installed "  $total_failures " times **************"
      echo "**********************************************************"
      echo "**********************************************************"
      echo "**********************************************************"
      echo "**********************************************************"
      echo "**********************************************************" 
    fi
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
  done
return
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
  sudo apt-get -y remove docker-scan-plugin
  sudo apt-get -y docker-ce-cli
  sudo apt-get -y docker-ce-rootless-extras
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
  sudo rm -rf /var/lib/kubelet/*
  sudo rm -f /etc/systemd/system/kubelet.service
  sudo rm -f /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  sudo rm -rf /sys/fs/cgroup/systemd/system.slice/docker.service
  sudo rm -rf /sys/fs/cgroup/systemd/system.slice/docker.socket
  sudo rm -rf /sys/fs/cgroup/unified/system.slice/docker.service
  sudo rm -rf /sys/fs/cgroup/unified/system.slice/docker.socket
  sudo rm -rf /etc/apt/sources.list.d/docker.list
  sudo rm -rf /etc/init/docker.conf
  sudo rm -rf /etc/systemd/system/docker.socket
  sudo rm -rf /etc/systemd/system/docker.service
  sudo rm -rf /etc/systemd/system/sockets.target.wants/docker.socket
  sudo rm -rf /etc/systemd/system/multi-user.target.wants/docker.service
  sudo apt-get update
  #sudo umount /var/lib/kubelet/pods/*
  rm -r /tmp/umount.txt
  mount -l | grep "/var/lib/kubelet/pods/" > /tmp/umount.txt
  #sed 's^tmpfs on ^^g' |  sed 's^ tmpfs (rw,relatime,inode64)^^g' | /tmp/umount.txt
  sed 's^tmpfs on ^umount ^g; s^ type tmpfs (rw,relatime,inode64)^^g' /tmp/umount.txt > kubmounts.txt
  source ./kubmounts.txt
  echo "list of mounts is: " $(mount -l)
}

#if [ -z "$1" ]
#then
#  echo "missing parameter buildup or teardown"
#  exit 1
#fi

#case $1 in
#  buildup)
#    buildup
#    exit 0
#    ;;
#  teardown)
#    teardown
#    exit 0
#    ;;
#  *)
#    echo "invalid parameter, exit"
#    exit 1
#    ;;
#esac




