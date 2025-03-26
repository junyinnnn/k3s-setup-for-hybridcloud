# K3s Setup for Hybrid-Cloud

This project provides a tutorial on how to initialize a **Linux K3s setup** in a **multi-cloud or hybrid environment**.
---
## **0. Setting Up Tailscale Using Docker**
```bash
cd ts
docker-compose up -d
```
---

## **1. Setting Up the AWS Master Node**
Run the following command on the AWS master node:

```bash
curl -sfL https://get.k3s.io | sh -s - server \
    --cluster-init \
    --node-ip 100.114.208.67 \
    --advertise-address 100.114.208.67 \
    --tls-san 100.114.208.67 \
    --flannel-iface tailscale0 \
    --disable-cloud-controller
```
Get k3s node token for authentication
```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```
---

## **2. Setting Up the Homelab Worker Node**
Run this command on the homelab worker node:

```bash
curl -sfL https://get.k3s.io | \
  K3S_URL=https://100.114.208.67:6443 \
  K3S_TOKEN=K10cfd68a50c9dab7890a9ab622b95b6c7cdfb1b9c3759362555332a1ac96f87e97::server:098618ccd5a0d954584fbe17ec3ec99b \
  sh -s - agent \
    --node-ip 100.87.157.110 \
    --node-external-ip 100.87.157.110 \
    --flannel-iface tailscale0 \
    --kubelet-arg "node-ip=100.87.157.110"

```

---

### **3. Verification Steps**
Verify the cluster status:

```bash
sudo kubectl get nodes -o wide
sudo kubectl describe node <Node_name>
```

If everything is set up correctly, you should see your master and worker nodes in the cluster.
![image](https://github.com/user-attachments/assets/15c0d591-cea9-4cc9-80e4-7c7441085078)
- Master Node settings(label, annotation)
```bash
Name:               k3s-master
Roles:              control-plane,etcd,master
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=k3s-master
                    kubernetes.io/os=linux
                    node-role.kubernetes.io/control-plane=true
                    node-role.kubernetes.io/etcd=true
                    node-role.kubernetes.io/master=true
Annotations:        etcd.k3s.cattle.io/local-snapshots-timestamp: 2025-03-26T16:41:25Z
                    etcd.k3s.cattle.io/node-address: 100.114.208.67
                    etcd.k3s.cattle.io/node-name: k3s-master-5babfb2c
                    flannel.alpha.coreos.com/backend-data: {"VNI":1,"VtepMAC":"4e:5b:d0:a0:ba:a8"}
                    flannel.alpha.coreos.com/backend-type: vxlan
                    flannel.alpha.coreos.com/kube-subnet-manager: true
                    flannel.alpha.coreos.com/public-ip: 100.114.208.67
                    k3s.io/node-args:
                      ["server","--cluster-init","--node-ip","100.114.208.67","--advertise-address","100.114.208.67","--tls-san","100.114.208.67","--flannel-ifa...
                    k3s.io/node-config-hash: VGG2IOVP2KZWNP222S3QBNSRBQ524CZJM3ETLBRV7BJATZV43S3Q====
                    k3s.io/node-env: {"K3S_TOKEN":"********"}
                    node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true

```
- Worker Node settings(label, annotation)
```bash
Name:               selfhost-torres
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=selfhost-torres
                    kubernetes.io/os=linux
Annotations:        flannel.alpha.coreos.com/backend-data: {"VNI":1,"VtepMAC":"46:2d:99:d6:3f:1e"}
                    flannel.alpha.coreos.com/backend-type: vxlan
                    flannel.alpha.coreos.com/kube-subnet-manager: true
                    flannel.alpha.coreos.com/public-ip: 100.87.157.110
                    k3s.io/node-args:
                      ["agent","--node-ip","100.87.157.110","--node-external-ip","100.87.157.110","--flannel-iface","tailscale0","--kubelet-arg","node-ip=100.87...
                    k3s.io/node-config-hash: YICXTTEWG4L23J6YLWAPB4Y5NFDXUPHRGTF3TEL6AELFDNN7ACEQ====
                    k3s.io/node-env: {"K3S_TOKEN":"********","K3S_URL":"https://100.114.208.67:6443"}
                    node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true

```
---

### **4. Nginx Ingress Controller**
- Install **Helm** and deploy workloads.
```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=ClusterIP \
  --set controller.service.externalIPs[0]=100.114.208.67 \
  --set controller.ingressClassResource.default=true \
  --set controller.config.use-forwarded-headers=true
```
```bash
sudo kubectl get svc -n ingress-nginx
```
![image](https://github.com/user-attachments/assets/721f6308-0bc7-4f78-9c09-0383f811bee9)

---
### **5. Deployment Test**
```bash
sudo kubectl apply -f test.yaml
```
Wait for pod to create and start running, should take 20s.
```bash
curl http://100.114.208.67/test
```
```bash
IP: 127.0.0.1
IP: ::1
IP: 10.42.1.10
RemoteAddr: 10.42.1.7:36756
GET /test HTTP/1.1
Host: 100.114.208.67
User-Agent: curl/8.5.0
Accept: */*
X-Forwarded-For: 10.42.0.0
X-Forwarded-Host: 100.114.208.67
X-Forwarded-Port: 80
X-Forwarded-Proto: http
X-Forwarded-Scheme: http
X-Real-Ip: 10.42.0.0
X-Request-Id: c6f76951e792c755fad43fc08bdeff42
X-Scheme: http
```
![image](https://github.com/user-attachments/assets/a1211eef-9e0c-43b1-8110-984befdffbeb)

---

**🚀 Enjoy your multi-cloud K3s setup!**
