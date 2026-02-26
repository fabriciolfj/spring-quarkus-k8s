#!/bin/bash

set -e

echo "======================================"
echo "  Instalação MicroK8s + Ferramentas"
echo "======================================"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Verificar se é Ubuntu/Debian
if ! command -v snap &> /dev/null; then
    log_error "snap não encontrado. Este script requer Ubuntu/Debian."
    exit 1
fi

# ==============================
# 1. Instalar MicroK8s
# ==============================
log_info "Instalando MicroK8s..."
sudo snap install microk8s --classic

# ==============================
# 2. Configurar usuário
# ==============================
log_info "Configurando permissões do usuário..."
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube
newgrp microk8s << 'EOF'
echo "Grupo microk8s ativado"
EOF

# ==============================
# 3. Aguardar MicroK8s subir
# ==============================
log_info "Aguardando MicroK8s ficar pronto..."
microk8s status --wait-ready

# ==============================
# 4. Habilitar addons essenciais
# ==============================
log_info "Habilitando addons essenciais..."

microk8s enable dns
log_info "✓ DNS habilitado"

microk8s enable storage
log_info "✓ Storage habilitado"

microk8s enable helm3
log_info "✓ Helm3 habilitado"

microk8s enable ingress
log_info "✓ Ingress habilitado"

microk8s enable metrics-server
log_info "✓ Metrics Server habilitado"

# ==============================
# 5. Configurar kubectl e helm
# ==============================
log_info "Configurando kubectl e helm..."

# Exportar kubeconfig
mkdir -p ~/.kube
microk8s config > ~/.kube/config
chmod 600 ~/.kube/config

# Adicionar aliases no .bashrc
ALIASES="
# MicroK8s aliases
alias kubectl='microk8s kubectl'
alias helm='microk8s helm3'
alias mk='microk8s'
"

if ! grep -q "MicroK8s aliases" ~/.bashrc; then
    echo "$ALIASES" >> ~/.bashrc
    log_info "Aliases adicionados ao ~/.bashrc"
fi

# ==============================
# 6. Instalar kubectl standalone (opcional)
# ==============================
log_info "Instalando kubectl standalone..."
sudo snap install kubectl --classic

# ==============================
# 7. Verificar instalação
# ==============================
log_info "Verificando instalação..."
microk8s kubectl get nodes
microk8s kubectl get pods -A

# ==============================
# 8. Instalar Prometheus
# ==============================
log_warn "Deseja instalar o Prometheus via addon do MicroK8s? (recomendado)"
read -p "Instalar Prometheus? (s/n): " install_prometheus

if [[ "$install_prometheus" == "s" || "$install_prometheus" == "S" ]]; then
    log_info "Habilitando Prometheus..."
    microk8s enable prometheus
    log_info "✓ Prometheus habilitado"
    log_info "Acesse o Prometheus com:"
    echo "  microk8s kubectl port-forward svc/prometheus-k8s 9090:9090 -n monitoring"
    log_info "Acesse o Grafana com:"
    echo "  microk8s kubectl port-forward svc/grafana 3000:3000 -n monitoring"
    echo "  user: admin / senha: admin"
fi

# ==============================
# 9. Resumo final
# ==============================
echo ""
echo "======================================"
echo "  Instalação concluída!"
echo "======================================"
echo ""
log_info "Comandos úteis:"
echo "  microk8s status               # status do cluster"
echo "  microk8s kubectl get nodes    # listar nodes"
echo "  microk8s kubectl get pods -A  # listar todos os pods"
echo "  microk8s stop                 # parar o cluster"
echo "  microk8s start                # iniciar o cluster"
echo ""
log_warn "IMPORTANTE: Faça logout e login novamente para aplicar as permissões do grupo microk8s"
echo "  ou execute: newgrp microk8s"
echo ""