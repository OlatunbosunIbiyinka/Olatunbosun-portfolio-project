#!/bin/bash
# Safe Destroy Script - Handles AKS cluster that's still creating
# This script safely destroys infrastructure even if AKS is still being created

# Don't exit on error - we want to handle errors gracefully
set +e

echo "🔍 Checking Infrastructure Status..."

RESOURCE_GROUP="ola-rg-dev"
CLUSTER_NAME="ola-aks-dev"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if AKS cluster exists and its state
echo ""
echo "📊 Checking AKS Cluster Status..."
PROVISIONING_STATE=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query "provisioningState" -o tsv 2>&1 || echo "")
POWER_STATE=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query "powerState.code" -o tsv 2>&1 || echo "")

if [ -n "$PROVISIONING_STATE" ] && [ "$PROVISIONING_STATE" != "NotFound" ] && ! echo "$PROVISIONING_STATE" | grep -q "error\|not found" > /dev/null 2>&1; then
    echo "  Cluster State: $PROVISIONING_STATE"
    if [ -n "$POWER_STATE" ] && ! echo "$POWER_STATE" | grep -q "error\|not found" > /dev/null 2>&1; then
        echo "  Power State: $POWER_STATE"
    fi
    
    if [ "$PROVISIONING_STATE" = "Creating" ]; then
        echo ""
        echo "⚠️  WARNING: AKS cluster is still being created!"
        echo "   Terraform destroy will NOT delete the AKS cluster (it's not in state)."
        echo "   You have two options:"
        echo ""
        echo "   Option 1: Cancel AKS creation first (recommended for cost savings)"
        echo "     az aks delete --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --yes"
        echo "     (This will cancel the creation and delete the cluster)"
        echo ""
        echo "   Option 2: Let Terraform destroy other resources, then manually delete AKS"
        echo "     terraform destroy -var-file=\"envs/dev/terraform.tfvars\""
        echo "     az aks delete --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --yes"
        
        echo ""
        read -p "   Choose option (1 or 2, or 'c' to cancel): " choice
        
        if [ "$choice" = "1" ]; then
            echo ""
            echo "🗑️  Canceling AKS cluster creation..."
            az aks delete --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --yes > /dev/null 2>&1 || true
            echo "   Waiting for deletion to start (this may take a few minutes)..."
            sleep 30
            
            # Wait for cluster to be deleted or creation to be canceled
            MAX_WAIT=10
            WAITED=0
            while [ $WAITED -lt $MAX_WAIT ]; do
                STATUS=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query "provisioningState" -o tsv 2>&1 || echo "NotFound")
                if [ "$STATUS" = "NotFound" ] || [ "$STATUS" = "Deleting" ] || [ "$STATUS" = "Failed" ]; then
                    break
                fi
                echo "   Still canceling... ($WAITED/$MAX_WAIT)"
                sleep 30
                WAITED=$((WAITED + 1))
            done
            
            echo ""
            echo "✅ Proceeding with Terraform destroy..."
        elif [ "$choice" = "2" ]; then
            echo ""
            echo "⚠️  Proceeding with Terraform destroy (AKS will need manual deletion)"
        else
            echo ""
            echo "❌ Cancelled"
            exit 0
        fi
    elif [ "$PROVISIONING_STATE" = "Succeeded" ]; then
        echo ""
        echo "✅ Cluster is ready. Terraform destroy will handle it."
    elif [ "$PROVISIONING_STATE" = "Deleting" ]; then
        echo ""
        echo "⏳ Cluster is already being deleted. Waiting..."
    fi
else
    echo "  ✅ AKS cluster doesn't exist or was already deleted"
    PROVISIONING_STATE="NotFound"
fi

# Check Terraform state
echo ""
echo "📋 Checking Terraform State..."
cd "$SCRIPT_DIR"
STATE_RESOURCES=$(terraform state list 2>&1 || echo "")
RESOURCE_COUNT=$(echo "$STATE_RESOURCES" | grep -c . || echo "0")

echo "  Found $RESOURCE_COUNT resources in Terraform state"

# Show what will be destroyed
echo ""
echo "📊 Resources that will be destroyed:"
terraform plan -destroy -var-file="envs/dev/terraform.tfvars" -out=destroy.tfplan 2>&1 | grep -E "will be destroyed|Plan:" | head -10 || true

# Confirm before destroying
echo ""
echo "⚠️  This will destroy all resources in Terraform state!"
read -p "   Type 'yes' to continue, or anything else to cancel: " confirm

if [ "$confirm" = "yes" ]; then
    echo ""
    echo "🗑️  Destroying infrastructure..."
    terraform destroy -var-file="envs/dev/terraform.tfvars" -auto-approve
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Terraform destroy completed!"
        
        # Check for orphaned federated credentials (common issue)
        echo ""
        echo "🔍 Checking for orphaned resources in state..."
        FEDERATED=$(terraform state list 2>&1 | grep "federated" || true)
        if [ -n "$FEDERATED" ]; then
            echo "   ⚠️  Found orphaned federated credentials in state"
            echo "   Cleaning up..."
            echo "$FEDERATED" | while read -r line; do
                terraform state rm "$line" > /dev/null 2>&1 || true
            done
            echo "   ✅ Cleaned up orphaned resources"
        fi
        
        # Check if AKS still exists
        AKS_CHECK=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query "provisioningState" -o tsv 2>&1 || echo "NotFound")
        if [ -n "$AKS_CHECK" ] && [ "$AKS_CHECK" != "NotFound" ] && ! echo "$AKS_CHECK" | grep -q "error\|not found" > /dev/null 2>&1; then
            echo ""
            echo "⚠️  AKS cluster still exists (it wasn't in Terraform state)"
            echo "   To delete it manually:"
            echo "   az aks delete --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --yes"
        else
            echo ""
            echo "✅ All resources destroyed!"
        fi
        
        # Verify Resource Group
        echo ""
        echo "🔍 Verifying cleanup..."
        RG_EXISTS=$(az group show --name "$RESOURCE_GROUP" --query "name" -o tsv 2>&1 || echo "")
        if [ -n "$RG_EXISTS" ]; then
            RG_RESOURCES=$(az resource list --resource-group "$RESOURCE_GROUP" --query "length(@)" -o tsv || echo "0")
            if [ "$RG_RESOURCES" -gt 0 ]; then
                echo "   ⚠️  Resource Group still contains $RG_RESOURCES resource(s)"
                echo "   To delete Resource Group:"
                echo "   az group delete --name $RESOURCE_GROUP --yes --no-wait"
            else
                echo "   ✅ Resource Group is empty"
                echo "   To delete Resource Group:"
                echo "   az group delete --name $RESOURCE_GROUP --yes"
            fi
        else
            echo "   ✅ Resource Group already deleted"
        fi
        
        # Check for CloudShell connection resource groups
        echo ""
        echo "🔍 Checking for CloudShell connection resource groups..."
        CLOUDSHELL_RGS=$(az group list --query "[?contains(name, 'RG-CloudShell-PrivateClusterConnection')].name" -o tsv 2>&1 || echo "")
        if [ -n "$CLOUDSHELL_RGS" ] && ! echo "$CLOUDSHELL_RGS" | grep -q "error\|not found" > /dev/null 2>&1; then
            COUNT=$(echo "$CLOUDSHELL_RGS" | grep -c . || echo "0")
            if [ "$COUNT" -gt 0 ]; then
                echo "   ⚠️  Found CloudShell connection resource groups (temporary RGs from accessing private AKS via Cloud Shell)"
                echo "   These are safe to delete. To clean them up:"
                echo "   ./cleanup-cloudshell-rgs.sh"
            else
                echo "   ✅ No CloudShell connection resource groups found"
            fi
        else
            echo "   ✅ No CloudShell connection resource groups found"
        fi
        
        # Final state check
        echo ""
        echo "📋 Final Terraform State Check..."
        FINAL_STATE=$(terraform state list 2>&1 || echo "")
        FINAL_COUNT=$(echo "$FINAL_STATE" | grep -c . || echo "0")
        if [ "$FINAL_COUNT" -eq 0 ]; then
            echo "   ✅ Terraform state is clean - ready for next apply!"
        else
            echo "   ⚠️  Terraform state still contains $FINAL_COUNT resource(s)"
            echo "   Review with: terraform state list"
        fi
    else
        echo ""
        echo "❌ Terraform destroy had errors. Check output above."
        echo ""
        echo "💡 Common fixes:"
        echo "   1. If federated credentials error: terraform state list | grep 'federated' | xargs -I {} terraform state rm {}"
        echo "   2. If resources still creating: Wait for completion or cancel manually"
        echo "   3. See SAFE_DESTROY_GUIDE.md for detailed troubleshooting"
    fi
else
    echo ""
    echo "❌ Destroy cancelled"
fi
