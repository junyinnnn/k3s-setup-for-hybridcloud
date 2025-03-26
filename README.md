# K3s Setup for Multi-Cloud

This project provides a tutorial on how to initialize a **Linux K3s setup** in a **multi-cloud or hybrid environment**.

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
![image](https://github.com/user-attachments/assets/36bf5206-f34f-4190-be76-dba0febdc6ab)

If everything is set up correctly, you should see your master and worker nodes in the cluster.

---

### **4. Nginx Ingress Controller**
- Install **Helm** and deploy workloads.
```bash
helm install ingress-nginx ingress-nginx/ingress-nginx   --namespace ingress-nginx   --create-namespace   --set controller.service.type=ClusterIP   --set controller.service.externalIPs[0]=100.114.208.67   --set controller.ingressClassResource.default=true
```
- No extra setup is needed, default is fine at this stage.

---
### **5. Deployment Test**
```bash
sudo kubectl apply -f test.yaml
```
---

**🚀 Enjoy your multi-cloud K3s setup!**
