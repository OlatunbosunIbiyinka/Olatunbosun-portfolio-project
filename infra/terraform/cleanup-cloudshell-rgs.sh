#!/bin/bash
# Cleanup CloudShell PrivateClusterConnection Resource Groups
# These are temporary resource groups created by Azure when accessing private AKS clusters from Cloud Shell

set +e

echo "🔍 Finding CloudShell connection resource groups..."

CLOUDSHELL_RGS=$(az group list --query "[?contains(name, 'RG-CloudShell-PrivateClusterConnection')].name" -o tsv 2>&1)

if [ -z "$CLOUDSHELL_RGS" ] || echo "$CLOUDSHELL_RGS" | grep -q "error\|not found" > /dev/null 2>&1; then
    echo "✅ No CloudShell connection resource groups found"
    exit 0
fi

COUNT=$(echo "$CLOUDSHELL_RGS" | grep -c . || echo "0")
echo ""
echo "Found $COUNT CloudShell connection resource group(s):"
echo "$CLOUDSHELL_RGS" | while read -r rg; do
    if [ -n "$rg" ]; then
        echo "  - $rg"
    fi
done

echo ""
echo "⚠️  These are temporary resource groups created by Azure Cloud Shell"
echo "   They can be safely deleted."
echo ""
read -p "Delete all CloudShell connection resource groups? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    echo ""
    echo "$CLOUDSHELL_RGS" | while read -r rg; do
        if [ -n "$rg" ]; then
            echo "🗑️  Deleting $rg..."
            az group delete --name "$rg" --yes --no-wait > /dev/null 2>&1
            echo "   ✅ Deleted"
        fi
    done
    echo ""
    echo "✅ Cleanup complete!"
else
    echo ""
    echo "❌ Cleanup cancelled"
fi
