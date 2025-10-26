#!/bin/bash

echo "=== Listmonk Deployment Status ==="
echo ""

echo "Namespace:"
kubectl get namespace listmonk

echo ""
echo "PostgreSQL Cluster:"
kubectl get cluster -n listmonk

echo ""
echo "Pods:"
kubectl get pods -n listmonk

echo ""
echo "Services:"
kubectl get svc -n listmonk

echo ""
echo "Ingress:"
kubectl get ingress -n listmonk

echo ""
echo "Certificates:"
kubectl get certificate -n listmonk

echo ""
echo "Backups:"
kubectl get backup -n listmonk 2>/dev/null || echo "No backups configured yet"

echo ""
echo "Recent Events:"
kubectl get events -n listmonk --sort-by='.lastTimestamp' | tail -10
