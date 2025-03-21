#!/bin/bash

# Script to set up K3s cluster with WireGuard VPN for n nodes using 10.0.0.0/24 CIDR
# Run this on each node with appropriate variables

# --- User Configurable Variables ---
NODE_ROLE="master"  # Set to "master" or "worker"
HOSTNAME="k3s-master"  # Set to "k3s-master" or "k3s-worker-<number>"
THIS_NODE_PUBLIC_IP="47.128.185.250"  # Public IP of this node
THIS_NODE_WG_IP="10.0.0.1"  # WireGuard IP for this node (e.g., 10.0.0.1 for master, 10.0.0.2 for worker 1, etc.)
THIS_NODE_WG_PRIVATE_KEY="qDmGa1Bnlnn7jWU16HegV020kfNOEgC3JWXkBkCUz3M="  # Generate with wg genkey
THIS_NODE_WG_PUBLIC_KEY="8BxmAuVrxBtWw+Z/QbIfhp/RDg5cw7qdNfE1Em7bIQo="    # Derived from private key with wg pubkey

# Cluster-wide configuration (set these on all nodes)
MASTER_PUBLIC_IP="47.128.185.250"  # Public IP of the master node
MASTER_WG_IP="10.0.0.1"     # WireGuard IP of the master (fixed)
MASTER_WG_PUBLIC_KEY="8BxmAuVrxBtWw+Z/QbIfhp/RDg5cw7qdNfE1Em7bIQo="  # Master's public key
K3S_TOKEN="your_k3s_token"  # Get from master after its K3s install (leave blank for master initially)

# Array of all nodes in the cluster (excluding this node, populated dynamically)
# Format: "PUBLIC_IP WG_IP WG_PUBLIC_KEY"
# Example: "y.y.y.y 10.0.0.2 worker1_public_key"
PEERS=(
    "52.184.80.128 10.0.0.2 zsmwRNeUER/Tnao5UB3CsIrfrJ7BtMclq2RuvODfyi8="
    #"z.z.z.z 10.0.0.3 worker2_public_key"
    # Add more peers as needed: "<public_ip> <wg_ip> <wg_public_key>"
)

# --- Step 1: Enable IP Forwarding ---
echo "Enabling IP forwarding..."
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.proxy_arp = 1" >> /etc/sysctl.conf
sysctl -p

# --- Step 2: Set Hostname ---
echo "Setting hostname to $HOSTNAME..."
hostnamectl set-hostname "$HOSTNAME"

# --- Step 3: Configure iptables ---
echo "Configuring iptables..."
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wg0 -o wg0 -m conntrack --ctstate NEW -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE

# --- Step 4: Install WireGuard Tools ---
echo "Installing wireguard-tools..."
apt update && apt install wireguard-tools -y

# --- Step 5: Generate Keys (Only if not provided) ---
if [ -z "$THIS_NODE_WG_PRIVATE_KEY" ]; then
    echo "Generating WireGuard keys for this node (run this step manually if keys are already provided)..."
    wg genkey | tee /tmp/privatekey | wg pubkey > /tmp/publickey
    echo "Private key: $(cat /tmp/privatekey)"
    echo "Public key: $(cat /tmp/publickey)"
    echo "Update the script with these keys and rerun."
    exit 1
fi

# --- Step 6: Configure WireGuard ---
echo "Setting up WireGuard configuration..."
mkdir -p /etc/wireguard
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $THIS_NODE_WG_PRIVATE_KEY
Address = $THIS_NODE_WG_IP
ListenPort = 5418
EOF

# Add all peers to WireGuard config
if [ "$NODE_ROLE" = "master" ]; then
    # Master includes all workers as peers
    for peer in "${PEERS[@]}"; do
        read -r peer_public_ip peer_wg_ip peer_wg_public_key <<< "$peer"
        cat >> /etc/wireguard/wg0.conf << EOF
[Peer]
PublicKey = $peer_wg_public_key
Endpoint = $peer_public_ip:5418
AllowedIPs = $peer_wg_ip/32
EOF
    done
else
    # Worker includes master and all other workers as peers
    # Add master as a peer
    cat >> /etc/wireguard/wg0.conf << EOF
[Peer]
PublicKey = $MASTER_WG_PUBLIC_KEY
Endpoint = $MASTER_PUBLIC_IP:5418
AllowedIPs = $MASTER_WG_IP/32
EOF
    # Add other workers (excluding this node)
    for peer in "${PEERS[@]}"; do
        read -r peer_public_ip peer_wg_ip peer_wg_public_key <<< "$peer"
        if [ "$peer_wg_ip" != "$THIS_NODE_WG_IP" ]; then
            cat >> /etc/wireguard/wg0.conf << EOF
[Peer]
PublicKey = $peer_wg_public_key
Endpoint = $peer_public_ip:5418
AllowedIPs = $peer_wg_ip/32
EOF
        fi
    done
fi

# --- Step 7: Start WireGuard ---
echo "Starting WireGuard..."
wg-quick up wg0

# --- Step 8: Enable WireGuard on Boot ---
echo "Enabling WireGuard on boot..."
systemctl enable wg-quick@wg0
wg syncconf wg0 <(wg-quick strip wg0)

# --- Step 9: Install K3s ---
echo "Installing K3s..."
if [ "$NODE_ROLE" = "master" ]; then
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-external-ip $THIS_NODE_PUBLIC_IP --advertise-address $THIS_NODE_PUBLIC_IP --node-ip $THIS_NODE_WG_IP --flannel-iface wg0" sh -
    # Extract token for worker nodes
    K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
    echo "K3s token: $K3S_TOKEN (save this for worker nodes)"
else
    if [ -z "$K3S_TOKEN" ]; then
        echo "Error: K3S_TOKEN is not set. Get it from the master node and set it in the script."
        exit 1
    fi
    curl -sfL https://get.k3s.io | K3S_URL="https://$MASTER_WG_IP:6443" K3S_TOKEN="$K3S_TOKEN" INSTALL_K3S_EXEC="--node-external-ip $THIS_NODE_PUBLIC_IP --node-ip $THIS_NODE_WG_IP --flannel-iface wg0" sh -
fi

# --- Step 10: Verify K3s (Master Only) ---
if [ "$NODE_ROLE" = "master" ]; then
    echo "Checking cluster status..."
    sleep 10  # Wait for K3s to stabilize
    kubectl get nodes -o wide
fi

echo "Setup complete for $HOSTNAME!"
