#!/bin/bash
# Diagnose GKE Autoscaling Issues
# This script helps identify why pods aren't being scheduled and nodes aren't scaling

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if user is authenticated to the cluster
if ! kubectl get nodes &> /dev/null; then
    echo -e "${RED}Error: Not authenticated to the Kubernetes cluster${NC}"
    echo "Please run: gcloud container clusters get-credentials CLUSTER_NAME --zone ZONE --project PROJECT_ID"
    exit 1
fi

echo -e "${BLUE}=== GKE Autoscaler Diagnostic Tool ===${NC}"

# 1. Check for pending pods
echo -e "\n${BLUE}Checking for pending pods...${NC}"
PENDING_PODS=$(kubectl get pods --all-namespaces | grep Pending || echo "None")
if [ "$PENDING_PODS" != "None" ]; then
    echo -e "${ORANGE}Found pending pods:${NC}"
    kubectl get pods --all-namespaces | grep Pending
    
    # Get the first pending pod
    FIRST_POD=$(kubectl get pods --all-namespaces | grep Pending | head -n 1)
    NAMESPACE=$(echo $FIRST_POD | awk '{print $1}')
    POD_NAME=$(echo $FIRST_POD | awk '{print $2}')
    
    echo -e "\n${BLUE}Checking why pod $POD_NAME in namespace $NAMESPACE isn't scheduling...${NC}"
    kubectl describe pod $POD_NAME -n $NAMESPACE | grep -A 10 "Events:"
    
    # Check pod resource requirements
    echo -e "\n${BLUE}Checking resource requirements for pod $POD_NAME:${NC}"
    kubectl get pod $POD_NAME -n $NAMESPACE -o json | jq '.spec.containers[].resources'
    
    # Check if pod has node selectors
    echo -e "\n${BLUE}Checking if the pod has node selectors:${NC}"
    NODE_SELECTOR=$(kubectl get pod $POD_NAME -n $NAMESPACE -o json | jq '.spec.nodeSelector')
    echo $NODE_SELECTOR
    
    # Check if pod has affinity rules
    echo -e "\n${BLUE}Checking if the pod has affinity rules:${NC}"
    AFFINITY=$(kubectl get pod $POD_NAME -n $NAMESPACE -o json | jq '.spec.affinity')
    echo $AFFINITY
else
    echo -e "${GREEN}No pending pods found.${NC}"
fi

# 2. Check node pool configuration
echo -e "\n${BLUE}Checking node pool configuration...${NC}"
NODE_POOLS=$(kubectl get nodes --show-labels)
echo "$NODE_POOLS"

# 3. Check cluster autoscaler status
echo -e "\n${BLUE}Checking cluster autoscaler status...${NC}"
kubectl get events --sort-by=.metadata.creationTimestamp | grep -i "autoscal" || echo "No recent autoscaler events found"

# 4. Check autoscaler logs for errors
echo -e "\n${BLUE}Checking autoscaler logs for errors...${NC}"
kubectl logs -n kube-system -l k8s-app=cluster-autoscaler --tail=50 | grep -i "error\|cannot\|fail\|scale up\|predicate" || echo "No relevant autoscaler errors found"

# 5. Check cluster capacity
echo -e "\n${BLUE}Checking cluster resource capacity and allocations...${NC}"
kubectl describe nodes | grep -A 5 "Allocated resources" 

echo -e "\n${BLUE}=== Diagnostics Complete ===${NC}"

echo -e "\n${BLUE}Recommended Solutions:${NC}"
echo -e "${GREEN}1. Check if pod architecture requirements match node architecture (arm64 vs amd64)${NC}"
echo -e "${GREEN}2. Ensure pods don't request more resources than available on a single node${NC}"
echo -e "${GREEN}3. Verify that any required node selectors or labels are configured on the node pool${NC}"
echo -e "${GREEN}4. Check for proper taints and tolerations if used${NC}"
echo -e "${GREEN}5. Verify that GCP resource quotas aren't limiting autoscaling${NC}"
