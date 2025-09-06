#!/bin/bash

# Bottle Story Production Deployment Script
# Usage: ./deploy-all.sh [service_name] or ./deploy-all.sh all

set -e

# Configuration
NAMESPACE="bottle-story-prod"
AWS_REGION="ap-northeast-2"
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-"123456789012"}
SERVICES=("member" "bottle" "realtime" "weather" "batch" "frontend")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if helm is available
    if ! command -v helm &> /dev/null; then
        error "helm is not installed or not in PATH"
        exit 1
    fi
    
    # Check if aws cli is available
    if ! command -v aws &> /dev/null; then
        error "aws cli is not installed or not in PATH"
        exit 1
    fi
    
    # Check kubectl connection
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# Create namespace and common resources
setup_namespace() {
    log "Setting up namespace and common resources..."
    
    # Apply namespace
    kubectl apply -f ../common/namespace.yaml
    
    # Apply network policies
    kubectl apply -f ../common/network-policy.yaml
    
    # Wait for namespace to be ready
    kubectl wait --for=condition=Ready namespace/$NAMESPACE --timeout=60s
    
    success "Namespace and common resources created"
}

# Deploy a specific service
deploy_service() {
    local service=$1
    log "Deploying $service service..."
    
    # Map service names to directory names
    case $service in
        "bottle")
            dir="bottlesv"
            ;;
        "weather")
            dir="wheatherbgm"
            ;;
        *)
            dir=$service
            ;;
    esac
    
    # Check if service directory exists
    if [ ! -d "../$dir" ]; then
        error "Service directory ../$dir does not exist"
        return 1
    fi
    
    # Apply ConfigMap and Secrets
    log "Applying ConfigMap and Secrets for $service..."
    if [ -f "../$dir/secret/configmap.yaml" ]; then
        envsubst < "../$dir/secret/configmap.yaml" | kubectl apply -f -
    fi
    
    if [ -f "../$dir/secret/secret.yaml" ]; then
        envsubst < "../$dir/secret/secret.yaml" | kubectl apply -f -
    fi
    
    # Deploy with Helm
    log "Deploying $service with Helm..."
    helm upgrade --install "$service-service-prod" "../$dir/helm" \
        --values "../$dir/helm/values-prod.yaml" \
        --namespace $NAMESPACE \
        --set image.repository="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/bottle-story/$service" \
        --wait --timeout=10m
    
    # Wait for rollout to complete
    log "Waiting for $service deployment to be ready..."
    kubectl rollout status deployment/"$service-service-deployment" -n $NAMESPACE --timeout=600s
    
    success "$service service deployed successfully"
}

# Deploy ALB Ingress
deploy_ingress() {
    log "Deploying ALB Ingress..."
    
    # Substitute environment variables and apply
    envsubst < ../common/alb-ingress.yaml | kubectl apply -f -
    
    # Wait for ingress to be ready
    log "Waiting for ALB to be provisioned..."
    kubectl wait --for=condition=Ready ingress/bottle-story-alb-ingress -n $NAMESPACE --timeout=600s
    
    # Get ALB endpoint
    ALB_ENDPOINT=$(kubectl get ingress bottle-story-alb-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    if [ -n "$ALB_ENDPOINT" ]; then
        success "ALB Ingress deployed successfully. Endpoint: $ALB_ENDPOINT"
    else
        warning "ALB endpoint not yet available. It may take a few minutes to provision."
    fi
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check pods
    echo -e "\n${BLUE}Pod Status:${NC}"
    kubectl get pods -n $NAMESPACE -o wide
    
    # Check services
    echo -e "\n${BLUE}Service Status:${NC}"
    kubectl get svc -n $NAMESPACE
    
    # Check ingress
    echo -e "\n${BLUE}Ingress Status:${NC}"
    kubectl get ingress -n $NAMESPACE
    
    # Check HPA
    echo -e "\n${BLUE}HPA Status:${NC}"
    kubectl get hpa -n $NAMESPACE
    
    success "Deployment verification completed"
}

# Rollback deployment
rollback_service() {
    local service=$1
    log "Rolling back $service service..."
    
    helm rollback "$service-service-prod" -n $NAMESPACE
    
    success "$service service rolled back"
}

# Main deployment function
main() {
    local target=${1:-"all"}
    
    log "Starting Bottle Story Production Deployment"
    log "Target: $target"
    
    # Check prerequisites
    check_prerequisites
    
    # Setup namespace
    setup_namespace
    
    # Deploy services
    if [ "$target" = "all" ]; then
        log "Deploying all services..."
        for service in "${SERVICES[@]}"; do
            deploy_service "$service"
        done
        deploy_ingress
    elif [ "$target" = "ingress" ]; then
        deploy_ingress
    elif printf '%s\n' "${SERVICES[@]}" | grep -q "^$target$"; then
        deploy_service "$target"
    else
        error "Invalid target: $target"
        echo "Available targets: all, ingress, ${SERVICES[*]}"
        exit 1
    fi
    
    # Verify deployment
    verify_deployment
    
    success "Deployment completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "rollback")
        if [ -z "$2" ]; then
            error "Please specify service name for rollback"
            exit 1
        fi
        rollback_service "$2"
        ;;
    "verify")
        verify_deployment
        ;;
    *)
        main "$1"
        ;;
esac