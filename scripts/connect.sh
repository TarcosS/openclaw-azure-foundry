#!/bin/bash
# Connect to the OpenClaw VM via Azure AD SSH
set -e
RG="${1:-rg-openclaw}"
VM="${2:-vm-openclaw}"
echo "Connecting to $VM in $RG..."
az ssh vm --resource-group "$RG" --name "$VM"
