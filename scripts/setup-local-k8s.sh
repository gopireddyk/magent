#!/bin/bash
# ============================================================================
# LOCAL KUBERNETES SETUP SCRIPT
# ============================================================================
# Creates a local K8s cluster using Multipass VM with K3s and Podman
# Usage: ./scripts/setup-local-k8s.sh
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VM_NAME="k8s-research"
VM_CPUS=4
VM_MEMORY="8G"
VM_DISK="40G"
UBUNTU_VERSION="22.04"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is required but not installed."
        echo ""
        echo "Install with:"
        case "$1" in
            multipass)
                echo "  macOS:  brew install multipass"
                echo "  Linux:  sudo snap install multipass"
                echo "  Windows: winget install Canonical.Multipass"
                ;;
            kubectl)
                echo "  macOS:  brew install kubectl"
                echo "  Linux:  sudo snap install kubectl --classic"
                echo "  Windows: winget install Kubernetes.kubectl"
                ;;
            podman)
                echo "  macOS:  brew install podman"
                echo "  Linux:  sudo apt-get install podman"
                echo "  Windows: winget install RedHat.Podman"
                ;;
            jq)
                echo "  macOS:  brew install jq"
                echo "  Linux:  sudo apt-get install jq"
                ;;
        esac
        exit 1
    fi
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

echo ""
echo "========================================"
echo "  Local Kubernetes Setup"
echo "  Using: Multipass + K3s + Podman"
echo "========================================"
echo ""

# Check prerequisites
log_info "Checking prerequisites..."
check_command multipass
check_command kubectl
check_command jq
log_success "All prerequisites found!"

# Check if VM already exists
if multipass info "$VM_NAME" &>/dev/null; then
    log_warning "VM '$VM_NAME' already exists."
    read -p "Delete and recreate? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Deleting existing VM..."
        multipass delete "$VM_NAME" --purge 2>/dev/null || true
    else
        log_info "Using existing VM..."
        VM_EXISTS=true
    fi
fi

# Create VM if needed
if [[ "$VM_EXISTS" != "true" ]]; then
    log_info "Creating Multipass VM..."
    log_info "  Name: $VM_NAME"
    log_info "  CPUs: $VM_CPUS"
    log_info "  Memory: $VM_MEMORY"
    log_info "  Disk: $VM_DISK"
    echo ""

    # Check for cloud-init file
    CLOUD_INIT_FILE="infrastructure/multipass/cloud-init.yaml"
    if [[ -f "$CLOUD_INIT_FILE" ]]; then
        log_info "Using cloud-init configuration..."
        multipass launch \
            --name "$VM_NAME" \
            --cpus "$VM_CPUS" \
            --memory "$VM_MEMORY" \
            --disk "$VM_DISK" \
            --cloud-init "$CLOUD_INIT_FILE" \
            "$UBUNTU_VERSION"
    else
        log_warning "No cloud-init file found, using basic setup..."
        multipass launch \
            --name "$VM_NAME" \
            --cpus "$VM_CPUS" \
            --memory "$VM_MEMORY" \
            --disk "$VM_DISK" \
            "$UBUNTU_VERSION"

        # Manual K3s installation
        log_info "Installing K3s..."
        multipass exec "$VM_NAME" -- bash -c 'curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644'

        log_info "Installing Podman..."
        multipass exec "$VM_NAME" -- bash -c 'sudo apt-get update && sudo apt-get install -y podman buildah skopeo'
    fi

    log_success "VM created successfully!"
fi

# Wait for K3s to be ready
log_info "Waiting for K3s to be ready..."
for i in {1..30}; do
    if multipass exec "$VM_NAME" -- sudo k3s kubectl get nodes &>/dev/null; then
        log_success "K3s is ready!"
        break
    fi
    echo -n "."
    sleep 5
done
echo ""

# Setup kubeconfig on host
log_info "Setting up kubeconfig on host..."

KUBECONFIG_DIR="$HOME/.kube"
KUBECONFIG_FILE="$KUBECONFIG_DIR/k8s-research-config"

mkdir -p "$KUBECONFIG_DIR"

# Copy kubeconfig from VM
multipass exec "$VM_NAME" -- sudo cat /etc/rancher/k3s/k3s.yaml > "$KUBECONFIG_FILE"

# Get VM IP
VM_IP=$(multipass info "$VM_NAME" --format json | jq -r ".info.\"$VM_NAME\".ipv4[0]")
log_info "VM IP: $VM_IP"

# Update kubeconfig with VM IP
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/127.0.0.1/$VM_IP/g" "$KUBECONFIG_FILE"
else
    # Linux
    sed -i "s/127.0.0.1/$VM_IP/g" "$KUBECONFIG_FILE"
fi

chmod 600 "$KUBECONFIG_FILE"

log_success "Kubeconfig saved to: $KUBECONFIG_FILE"

# Verify connection
log_info "Verifying cluster connection..."
export KUBECONFIG="$KUBECONFIG_FILE"

if kubectl get nodes &>/dev/null; then
    log_success "Successfully connected to cluster!"
    echo ""
    kubectl get nodes
else
    log_error "Failed to connect to cluster"
    exit 1
fi

# Show cluster info
echo ""
log_info "Cluster information:"
echo ""
multipass exec "$VM_NAME" -- sudo k3s kubectl get nodes -o wide
echo ""
multipass exec "$VM_NAME" -- sudo k3s kubectl get pods -A
echo ""

# Print completion message
echo ""
echo "========================================"
echo -e "${GREEN}  Setup Complete!${NC}"
echo "========================================"
echo ""
echo "VM Name:     $VM_NAME"
echo "VM IP:       $VM_IP"
echo "Kubeconfig:  $KUBECONFIG_FILE"
echo ""
echo "To use the cluster:"
echo ""
echo "  export KUBECONFIG=$KUBECONFIG_FILE"
echo "  kubectl get nodes"
echo ""
echo "Or add to ~/.bashrc:"
echo ""
echo "  echo 'export KUBECONFIG=$KUBECONFIG_FILE' >> ~/.bashrc"
echo ""
echo "Other useful commands:"
echo ""
echo "  multipass shell $VM_NAME    # SSH into VM"
echo "  multipass stop $VM_NAME     # Stop VM"
echo "  multipass start $VM_NAME    # Start VM"
echo "  multipass delete $VM_NAME   # Delete VM"
echo ""
echo "To deploy the application:"
echo ""
echo "  kubectl apply -k infrastructure/kubernetes/overlays/dev"
echo ""
echo "========================================"
