# K3s Setup for Multi-Cloud

This project provides a tutorial on how to initialize a **Linux K3s setup** in a **multi-cloud or hybrid environment**.

---

## **1. Setting Up the AWS Master Node**
Run the following command on the AWS master node:

```bash
curl -sfL https://get.k3s.io | sh -s - server \
    --cluster-init \
    --advertise-address <YOUR_PUBLIC_IP> \
    --tls-san <YOUR_PUBLIC_IP> \
    --node-ip <PRIVATE_IP> \
    --node-external-ip <YOUR_PUBLIC_IP>
sudo cat /var/lib/rancher/k3s/server/node-token
export K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
echo $K3S_TOKEN
```

---

## **2. Setting Up the Homelab Worker Node**
Run this command on the homelab worker node:

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://<MASTER_PRIVATE_IP>:6443 \
    K3S_TOKEN=<K3S_CLUSTER_TOKEN> \
    sh -s - agent \
    --node-ip <WORKER_PRIVATE_IP> \
    --node-external-ip <WORKER_PUBLIC_IP>
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
