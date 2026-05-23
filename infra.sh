#!/usr/bin/env bash
set -e

RG="rg-petcare"
LOCATION="canadacentral"

VNET="vnet_petcare"
SUBNET="subnet_petcare"

NSG="nsg_petcare"

VM="vm-petcare"

ADMIN="azureuser"

echo "Criando Resource Group..."

az group create \
  --name "$RG" \
  --location "$LOCATION"

echo "Criando VNET e SUBNET..."

az network vnet create \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --name "$VNET" \
  --address-prefixes 10.10.0.0/16 \
  --subnet-name "$SUBNET" \
  --subnet-prefixes 10.10.1.0/24

echo "Criando NSG..."

az network nsg create \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --name "$NSG"

echo "Criando VM Linux..."

az vm create \
  --resource-group "$RG" \
  --name "$VM" \
  --image Ubuntu2204 \
  --size Standard_D2s_v3 \
  --admin-username "$ADMIN" \
  --generate-ssh-keys \
  --vnet-name "$VNET" \
  --subnet "$SUBNET" \
  --nsg "$NSG"

echo "Abrindo porta SSH..."

az vm open-port \
  --resource-group "$RG" \
  --name "$VM" \
  --port 22

echo "Abrindo porta da API..."

az vm open-port \
  --resource-group "$RG" \
  --name "$VM" \
  --port 8080

echo "Instalando Docker e ferramentas..."

az vm run-command invoke \
  --resource-group "$RG" \
  --name "$VM" \
  --command-id RunShellScript \
  --scripts "
    sudo apt-get update &&
    sudo apt-get install -y \
      git nano curl ca-certificates docker-compose-plugin &&
    curl -fsSL https://get.docker.com | sudo sh &&
    sudo usermod -aG docker azureuser
  "

echo "IP PUBLICO DA VM:"

az vm show \
  --resource-group "$RG" \
  --name "$VM" \
  --show-details \
  --query publicIps \
  --output tsv