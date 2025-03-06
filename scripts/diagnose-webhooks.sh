#!/bin/bash
# Diagnose Webhook Issues in GKE

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== GKE Webhook Diagnostic Tool ===${NC}"

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

# 1. Check for ValidatingWebhookConfigurations
echo -e "\n${BLUE}Checking ValidatingWebhookConfigurations...${NC}"
VALIDATING_WEBHOOKS=$(kubectl get validatingwebhookconfigurations -o name 2>/dev/null || echo "None")
if [ "$VALIDATING_WEBHOOKS" != "None" ]; then
    echo -e "${ORANGE}Found ValidatingWebhookConfigurations:${NC}"
    kubectl get validatingwebhookconfigurations
    
    # For each webhook, check if the service exists and has endpoints
    for webhook in $(kubectl get validatingwebhookconfigurations -o name | cut -d/ -f2); do
        echo -e "\n${BLUE}Analyzing ValidatingWebhookConfiguration: ${webhook}${NC}"
        
        # Get service references from the webhook
        SERVICE_REFS=$(kubectl get validatingwebhookconfigurations $webhook -o json | \
                      jq -r '.webhooks[] | select(.clientConfig.service != null) | "\(.clientConfig.service.namespace) \(.clientConfig.service.name)"' 2>/dev/null || echo "")
        
        if [ -z "$SERVICE_REFS" ]; then
            echo -e "${ORANGE}No service references found in this webhook. It may be using URL callbacks instead.${NC}"
            continue
        fi
        
        echo "$SERVICE_REFS" | while read -r line; do
            if [ -z "$line" ]; then continue; fi
            
            NAMESPACE=$(echo $line | cut -d' ' -f1)
            SERVICE_NAME=$(echo $line | cut -d' ' -f2)
            
            echo -e "${BLUE}Checking service $SERVICE_NAME in namespace $NAMESPACE:${NC}"
            
            # Check if service exists
            if ! kubectl get service $SERVICE_NAME -n $NAMESPACE &> /dev/null; then
                echo -e "${RED}  ⨯ Service $SERVICE_NAME does not exist in namespace $NAMESPACE${NC}"
                continue
            fi
            
            echo -e "${GREEN}  ✓ Service $SERVICE_NAME exists in namespace $NAMESPACE${NC}"
            
            # Check if service has endpoints
            ENDPOINTS=$(kubectl get endpoints $SERVICE_NAME -n $NAMESPACE -o json | jq '.subsets[] | .addresses | length' 2>/dev/null || echo 0)
            if [ "$ENDPOINTS" = "0" ] || [ -z "$ENDPOINTS" ]; then
                echo -e "${RED}  ⨯ Service $SERVICE_NAME has no endpoints${NC}"
                
                # Get selector from service
                SELECTOR=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o json | jq -r '.spec.selector | to_entries | map("\(.key)=\(.value)") | join(",")' 2>/dev/null || echo "")
                if [ -z "$SELECTOR" ]; then
                    echo -e "${RED}  ⨯ Service has no selectors defined${NC}"
                else
                    echo -e "${BLUE}  Checking for pods matching selector: $SELECTOR${NC}"
                    MATCHING_PODS=$(kubectl get pods -n $NAMESPACE -l $SELECTOR 2>/dev/null || echo "None")
                    if [ "$MATCHING_PODS" = "None" ]; then
                        echo -e "${RED}  ⨯ No pods found matching this selector${NC}"
                    else
                        echo -e "${BLUE}  Pods matching the selector:${NC}"
                        kubectl get pods -n $NAMESPACE -l $SELECTOR
                        
                        # Check pod status
                        NOT_RUNNING=$(kubectl get pods -n $NAMESPACE -l $SELECTOR | grep -v "Running" | grep -v "NAME" || echo "")
                        if [ ! -z "$NOT_RUNNING" ]; then
                            echo -e "${RED}  ⨯ Some pods are not in Running state${NC}"
                            echo "$NOT_RUNNING"
                        fi
                    fi
                fi
            else
                echo -e "${GREEN}  ✓ Service $SERVICE_NAME has $ENDPOINTS endpoint(s)${NC}"
            fi
        done
    done
else
    echo -e "${GREEN}No ValidatingWebhookConfigurations found.${NC}"
fi

# 2. Check for MutatingWebhookConfigurations
echo -e "\n${BLUE}Checking MutatingWebhookConfigurations...${NC}"
MUTATING_WEBHOOKS=$(kubectl get mutatingwebhookconfigurations -o name 2>/dev/null || echo "None")
if [ "$MUTATING_WEBHOOKS" != "None" ]; then
    echo -e "${ORANGE}Found MutatingWebhookConfigurations:${NC}"
    kubectl get mutatingwebhookconfigurations
    
    # For each webhook, check if the service exists and has endpoints
    for webhook in $(kubectl get mutatingwebhookconfigurations -o name | cut -d/ -f2); do
        echo -e "\n${BLUE}Analyzing MutatingWebhookConfiguration: ${webhook}${NC}"
        
        # Get service references from the webhook
        SERVICE_REFS=$(kubectl get mutatingwebhookconfigurations $webhook -o json | \
                      jq -r '.webhooks[] | select(.clientConfig.service != null) | "\(.clientConfig.service.namespace) \(.clientConfig.service.name)"' 2>/dev/null || echo "")
        
        if [ -z "$SERVICE_REFS" ]; then
            echo -e "${ORANGE}No service references found in this webhook. It may be using URL callbacks instead.${NC}"
            continue
        fi
        
        echo "$SERVICE_REFS" | while read -r line; do
            if [ -z "$line" ]; then continue; fi
            
            NAMESPACE=$(echo $line | cut -d' ' -f1)
            SERVICE_NAME=$(echo $line | cut -d' ' -f2)
            
            echo -e "${BLUE}Checking service $SERVICE_NAME in namespace $NAMESPACE:${NC}"
            
            # Check if service exists
            if ! kubectl get service $SERVICE_NAME -n $NAMESPACE &> /dev/null; then
                echo -e "${RED}  ⨯ Service $SERVICE_NAME does not exist in namespace $NAMESPACE${NC}"
                continue
            fi
            
            echo -e "${GREEN}  ✓ Service $SERVICE_NAME exists in namespace $NAMESPACE${NC}"
            
            # Check if service has endpoints
            ENDPOINTS=$(kubectl get endpoints $SERVICE_NAME -n $NAMESPACE -o json | jq '.subsets[] | .addresses | length' 2>/dev/null || echo 0)
            if [ "$ENDPOINTS" = "0" ] || [ -z "$ENDPOINTS" ]; then
                echo -e "${RED}  ⨯ Service $SERVICE_NAME has no endpoints${NC}"
                
                # Get selector from service
                SELECTOR=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o json | jq -r '.spec.selector | to_entries | map("\(.key)=\(.value)") | join(",")' 2>/dev/null || echo "")
                if [ -z "$SELECTOR" ]; then
                    echo -e "${RED}  ⨯ Service has no selectors defined${NC}"
                else
                    echo -e "${BLUE}  Checking for pods matching selector: $SELECTOR${NC}"
                    MATCHING_PODS=$(kubectl get pods -n $NAMESPACE -l $SELECTOR 2>/dev/null || echo "None")
                    if [ "$MATCHING_PODS" = "None" ]; then
                        echo -e "${RED}  ⨯ No pods found matching this selector${NC}"
                    else
                        echo -e "${BLUE}  Pods matching the selector:${NC}"
                        kubectl get pods -n $NAMESPACE -l $SELECTOR
                        
                        # Check pod status
                        NOT_RUNNING=$(kubectl get pods -n $NAMESPACE -l $SELECTOR | grep -v "Running" | grep -v "NAME" || echo "")
                        if [ ! -z "$NOT_RUNNING" ]; then
                            echo -e "${RED}  ⨯ Some pods are not in Running state${NC}"
                            echo "$NOT_RUNNING"
                        fi
                    fi
                fi
            else
                echo -e "${GREEN}  ✓ Service $SERVICE_NAME has $ENDPOINTS endpoint(s)${NC}"
            fi
        done
    done
else
    echo -e "${GREEN}No MutatingWebhookConfigurations found.${NC}"
fi

echo -e "\n${BLUE}=== Diagnostics Complete ===${NC}"

# Provide recommendations
echo -e "\n${BLUE}Recommendations:${NC}"
echo -e "${GREEN}1. For webhooks with no endpoints, check if the webhook pods are running${NC}"
echo -e "${GREEN}2. For ARM-based clusters, ensure webhook container images support ARM64 architecture${NC}"
echo -e "${GREEN}3. If you're not using these webhooks, consider deleting them:${NC}"
echo -e "${GREEN}   kubectl delete validatingwebhookconfigurations [webhook-name]${NC}"
echo -e "${GREEN}   kubectl delete mutatingwebhookconfigurations [webhook-name]${NC}"
echo -e "${GREEN}4. Alternatively, update them to target available endpoints or URL callbacks${NC}"
echo -e "${GREEN}5. If webhook pods fail to start, check for architecture compatibility and resource requirements${NC}"
