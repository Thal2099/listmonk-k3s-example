#!/bin/bash

set -e

echo "Setting up AWS Parameter Store secrets for Listmonk..."

read -p "Enter database username [listmonk]: " DB_USER
DB_USER=${DB_USER:-listmonk}

read -sp "Enter database password: " DB_PASS
echo

read -p "Enter database superuser username [postgres]: " DB_SUPERUSER
DB_SUPERUSER=${DB_SUPERUSER:-postgres}

read -sp "Enter database superuser password: " DB_SUPERUSER_PASS
echo

aws ssm put-parameter --name /listmonk/db/username --value "$DB_USER" --type SecureString --overwrite
aws ssm put-parameter --name /listmonk/db/password --value "$DB_PASS" --type SecureString --overwrite
aws ssm put-parameter --name /listmonk/db/superuser/username --value "$DB_SUPERUSER" --type SecureString --overwrite
aws ssm put-parameter --name /listmonk/db/superuser/password --value "$DB_SUPERUSER_PASS" --type SecureString --overwrite

echo "Secrets stored successfully in AWS Parameter Store!"
