#!/bin/bash
set -e

echo "============================================"
echo "🚀 VM Initial Setup Script"
echo "============================================"

# === 1. System Update ===
echo "📦 Actualizando sistema..."
apt-get update -y
apt-get upgrade -y
apt-get autoremove -y
apt-get autoclean -y

# === 2. Essential Tools ===
echo "🔧 Instalando herramientas esenciales..."
apt-get install -y \
    curl wget git nano vim tree \
    ca-certificates gnupg \
    lsb-release software-properties-common \
    ucommon-utils htop unzip zip \
    net-tools dnsutils \
    fail2ban ufw

# === 3. Docker V2 (official method) ===
echo "🐳 Instalando Docker V2..."
if command -v docker &> /dev/null; then
    echo "⏭️  Docker ya está instalado: $(docker --version)"
else
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker
    systemctl start docker
    echo "✅ Docker instalado: $(docker --version)"
fi

# === 4. Docker Compose V2 plugin ===
echo "🐳 Instalando Docker Compose V2..."
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64 \
    -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose
echo "✅ Docker Compose: $(docker compose version)"

# === 5. NGINX + Certbot ===
echo "🌐 Instalando NGINX y Certbot..."
apt-get install -y nginx certbot python3-certbot-nginx
systemctl enable nginx
systemctl start nginx
echo "✅ NGINX: $(nginx -v 2>&1)"

# === 6. Firewall (UFW) ===
echo "🔒 Configurando Firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
echo "✅ Firewall activo:"
ufw status

# === 7. Fail2Ban (brute force protection) ===
echo "🛡️  Configurando Fail2Ban..."
systemctl enable fail2ban
systemctl start fail2ban
echo "✅ Fail2Ban activo"

# === 8. Swap (recommended for small VMs) ===
echo "💾 Configurando Swap (2GB)..."
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "✅ Swap de 2GB creado y activado"
else
    echo "⏭️  Swap ya existe"
fi

# === 9. SSH Hardening ===
echo "🔐 Endureciendo SSH..."
sed -i 's/#PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl reload sshd
echo "✅ SSH: root solo por clave, password auth desactivado"

# === 10. System Limits (for Docker workloads) ===
echo "⚙️  Optimizando límites del sistema..."
cat >> /etc/sysctl.conf <<EOF

# Optimizations for Docker/n8n
vm.swappiness=10
net.core.somaxconn=65535
net.ipv4.tcp_max_syn_backlog=65535
EOF
sysctl -p

# === Summary ===
echo ""
echo "============================================"
echo "✅ VM Setup Completado"
echo "============================================"
echo "  Docker:        $(docker --version)"
echo "  Compose:       $(docker compose version)"
echo "  NGINX:         $(nginx -v 2>&1)"
echo "  Firewall:      UFW activo (80, 443, SSH)"
echo "  Protección:    Fail2Ban activo"
echo "  Swap:          $(swapon --show | tail -1)"
echo "============================================"
echo ""
echo "⚠️  IMPORTANTE: Verifica que tu clave SSH"
echo "   esté en ~/.ssh/authorized_keys ANTES"
echo "   de cerrar esta sesión (SSH hardening activo)"
echo ""
