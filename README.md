# k3s-setup-for-multicloud
This project provides tutorial on how to initialize a linux k3s setup in a multicloud or hybrid environments


curl -sfL https://get.k3s.io | sh -s - server   --cluster-init   --advertise-address 100.114.208.67   --tls-san 100.114.208.67   --node-ip 100.114.208.67   --node-external-ip 100.114.208.67
