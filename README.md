# Listmonk on K3s - Complete Setup Guide

Self-hosted newsletter platform using Listmonk on Kubernetes (K3s).

## Prerequisites

- A server with at least 2 vCPUs and 8GB RAM (Hetzner CCX13 recommended)
- Ubuntu 24.04
- A domain name
- AWS account (for Parameter Store - free tier)
- Hetzner Cloud account (for Object Storage backups)

## Cost Breakdown

- Server: €12/month (Hetzner CCX13)
- Backups: ~€0-5/month (Hetzner Object Storage)
- Email sending: ~$0.4 per 1,000 emails (Maileroo or similar)

## Quick Start

### 1. Server Setup

```bash
ssh root@<your-server-ip>

apt update && apt upgrade -y
apt install -y curl wget git ufw

ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 6443/tcp
ufw enable
```

### 2. Install K3s

```bash
curl -s https://get.k3s.io | \
  INSTALL_K3S_CHANNEL=stable \
  INSTALL_K3S_EXEC="--secrets-encryption" \
  sh -

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc

kubectl get nodes
```

### 3. Install CloudNativePG

```bash
kubectl apply --server-side -f \
  https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.27/releases/cnpg-1.27.1.yaml

kubectl rollout status deployment \
  -n cnpg-system cnpg-controller-manager
```

### 4. Install External Secrets Operator

```bash
kubectl apply -f external-secrets/
```

### 5. Configure AWS Credentials

```bash
kubectl create secret generic aws-credentials \
  --from-literal=access-key-id=YOUR_ACCESS_KEY \
  --from-literal=secret-access-key=YOUR_SECRET_KEY \
  -n external-secrets
```

### 6. Store Secrets in AWS Parameter Store

```bash
aws ssm put-parameter --name /listmonk/db/username --value "listmonk" --type SecureString --overwrite
aws ssm put-parameter --name /listmonk/db/password --value "CHANGE_ME_STRONG_PASSWORD" --type SecureString --overwrite
aws ssm put-parameter --name /listmonk/db/superuser/username --value "postgres" --type SecureString --overwrite
aws ssm put-parameter --name /listmonk/db/superuser/password --value "CHANGE_ME_SUPERUSER_PASSWORD" --type SecureString --overwrite
```

### 7. Deploy PostgreSQL

```bash
kubectl create namespace listmonk
kubectl apply -f postgres/
kubectl wait --for=condition=Ready cluster/pg-listmonk -n listmonk --timeout=5m
```

### 8. Install cert-manager

```bash
kubectl apply -f cert-manager/

# Update email in cert-manager/cluster-issuer.yml before applying
kubectl apply -f cert-manager/cluster-issuer.yml
```

### 9. Deploy Listmonk

Update `listmonk/config.toml` with your domain, then:

```bash
kubectl apply -k listmonk/
kubectl wait --for=condition=Ready pod -l app=listmonk -n listmonk --timeout=5m
```

### 10. Configure Backups

```bash
# Create Hetzner Object Storage credentials
kubectl create secret generic hetzner-blob-storage \
  --from-literal=ACCESS_KEY_ID=your-access-key \
  --from-literal=ACCESS_SECRET_KEY=your-secret-key \
  -n listmonk

# Apply backup configuration
kubectl apply -f postgres/objectstore.yml
kubectl apply -f postgres/scheduledbackup.yml
```

### 11. Point DNS

Add an A record:

- `newsletter.yourdomain.com` → `<your-server-ip>`

Wait 5-10 minutes for DNS propagation and SSL certificate issuance.

### 12. Access Listmonk

Navigate to `https://newsletter.yourdomain.com`

Default credentials are from your AWS Parameter Store values.

## Configuration

### Update Domain

Edit `listmonk/config.toml` and `listmonk/ingress.yml` with your domain.

### SMTP Settings

Configure in Listmonk UI under Settings → SMTP. Recommended providers:

- Maileroo
- AWS SES
- SendGrid
- Mailgun

## Maintenance

### Server Updates

```bash
apt update && apt upgrade -y
systemctl restart k3s
```

### Check Backup Status

```bash
kubectl get backup -n listmonk
```

### View Logs

```bash
kubectl logs -l app=listmonk -n listmonk -f
```

### Scale Resources

Edit `postgres/cluster.yml` and `listmonk/deployment.yml` to adjust resource limits.

## Troubleshooting

### PostgreSQL not starting

```bash
kubectl describe cluster pg-listmonk -n listmonk
kubectl logs -n cnpg-system -l app.kubernetes.io/name=cloudnative-pg
```

### Listmonk not accessible

```bash
kubectl get ingress -n listmonk
kubectl describe ingress listmonk -n listmonk
kubectl get certificate -n listmonk
```

### Backup failures

```bash
kubectl describe backup -n listmonk
kubectl logs -n listmonk -l postgresql=pg-listmonk
```

## License

Apache License 2.0

## Credits

Based on the guide: [Own Your Newsletter with Listmonk](https://meysam.io/blog/own-your-newsletter-with-listmonk)
