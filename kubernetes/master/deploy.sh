#/bin/bash
#ubuntu 21.04
#sudo apt-get install ssh
#sudo vi /etc/ssh/sshd_config
#add nopasswd
#service ssh restart

#build up
echo "Start build up"
sudo apt-get update
sudo apt-get install -y golang
sudo apt-get install -y libvirt
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys 7EA0A9C3F273FCD8
sudo apt-get update
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo apt-get install -y     apt-transport-https     ca-certificates     curl     gnupg     lsb-release
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo cp daemon.json /etc/docker/daemon.json
sudo systemctl restart docker
sudo snap list
sudo apt purge snapd
sudo swapoff -a
sudo ufw disable
sudo apt-get update
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo bash -c 'echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list'
sudo apt-get update 
sudo apt-get install -y kubernetes
sudo apt-get install -y kubectl
sudo apt-get install -y kubeadm
sudo apt-get install -y kubelet
sudo systemctl enable kubelet
sudo systemctl start kubelet
sudo kubeadm init --apiserver-advertise-address=192.168.253.170

#install weave networking
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

#install flannel networking
#wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl cluster-info
kubectl get pods --all-namespaces
kubectl get nodes
kubectl describe node kube-master
kubectl get services --all-namespaces
kubectl get deployments

#install dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml
kubectl proxy

kubectl apply -f kubernetes-dashboard-anonymous.yaml
kubectl create -f ./create-namespace.yaml
kubectl apply -f hello-world-container-deployment.yaml
kubectl apply -f deploy-pod.yaml
kubectl rollout restart deployment kube-master
exit 0

#tear down
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
sudo apt-get -y remove docker-ce-cli
sudo apt-get -y remove containerd.io
sudo apt-get -y remove docker-ce-rootless-extras
sudo apt-get -y remove docker-scan-plugin
sudo apt-get -y remove cri-tools
sudo apt-get -y remove golang
sudo apt-get -y remove libvirt
sudo apt -y autoremove
sudo rm -rf /etc/kubernetes
sudo rm -rf /var/lib/docker

exit 0



