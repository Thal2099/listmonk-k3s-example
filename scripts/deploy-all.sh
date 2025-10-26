#!/bin/bash

set -e

echo "Deploying Listmonk on K3s..."

echo "1. Creating namespace..."
kubectl create namespace listmonk --dry-run=client -o yaml | kubectl apply -f -

echo "2. Applying PostgreSQL configuration..."
kubectl apply -f postgres/externalsecret-superuser.yml
kubectl apply -f postgres/externalsecret-user.yml
kubectl apply -f postgres/cluster.yml

echo "3. Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=Ready cluster/pg-listmonk -n listmonk --timeout=5m

echo "4. Deploying Listmonk..."
kubectl apply -k listmonk/

echo "5. Waiting for Listmonk to be ready..."
kubectl wait --for=condition=Ready pod -l app=listmonk -n listmonk --timeout=5m

echo "6. Setting up backups (optional)..."
read -p "Do you want to configure backups now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    kubectl apply -f postgres/objectstore.yml
    kubectl apply -f postgres/scheduledbackup.yml
    echo "Backups configured!"
fi

echo ""
echo "Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Point your DNS to this server's IP"
echo "2. Wait for SSL certificate to be issued (5-10 minutes)"
echo "3. Access Listmonk at your configured domain"
echo ""
