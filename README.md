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

sudo cat /var/lib/rancher/k3s/server/node-token
export K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
echo $K3S_TOKEN
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

## **3. Configuring K3s on the AWS Master Node**
After installation, modify the **kubeconfig** file on the AWS master node:

```bash
sudo nano /etc/rancher/k3s/k3s.yaml
```

### **Modify the `server` Field**
Change:

```yaml
server: https://127.0.0.1:6443
```
To:

```yaml
server: https://<MASTER_PRIVATE_IP>:6443
```

---

### **Verification Steps**
After making the changes, apply them and verify the cluster status:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes -o wide
```

If everything is set up correctly, you should see your master and worker nodes in the cluster.

---

### **Next Steps**
- Install **Helm** and deploy workloads.
- Set up **Ingress NGINX** for traffic routing.
- Configure **Persistent Storage** if needed.

---

**🚀 Enjoy your multi-cloud K3s setup!**
