# K3s Setup for Multi-Cloud

This project provides a tutorial on how to initialize a **Linux K3s setup** in a **multi-cloud or hybrid environment**.

---

## **1. Setting Up the AWS Master Node**
Run the following command on the AWS master node:

```bash
curl -sfL https://get.k3s.io | sh -s - server \
    --cluster-init \
    --advertise-address 100.114.208.67 \
    --tls-san 100.114.208.67 \
    --node-ip 100.114.208.67 \
    --node-external-ip 100.114.208.67
```

---

## **2. Setting Up the Homelab Worker Node**
Run this command on the homelab worker node:

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://100.114.208.67:6443 \
    K3S_TOKEN=K10fea86508552f32dc3e34c7a223bb4b35e30994d0167b4bed8b82a47cb52bc6c9::server:7c865c764247ba11bb359da87908f6ba \
    sh -s - agent \
    --node-ip 100.87.157.110 \
    --node-external-ip 100.87.157.110
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
server: https://100.114.208.67:6443
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
