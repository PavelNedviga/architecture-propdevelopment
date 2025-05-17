#!/usr/bin/env bash
# создаём учётки dev_sales и security_analyst в kube-config через клиентские сертификаты
# работает на локальном Minikube (CA-файлы в ~/.minikube)

set -euo pipefail
CLUSTER=minikube
CA_CERT="${HOME}/.minikube/ca.crt"
CA_KEY="${HOME}/.minikube/ca.key"

for USER in dev_sales security_analyst; do
  openssl genrsa -out "${USER}.key" 2048
  openssl req -new -key "${USER}.key" -out "${USER}.csr" -subj "/CN=${USER}/O=${USER}"
  openssl x509 -req -in "${USER}.csr" -CA "$CA_CERT" -CAkey "$CA_KEY" \
               -CAcreateserial -out "${USER}.crt" -days 365
  kubectl config set-credentials "${USER}" \
      --client-certificate="${USER}.crt" --client-key="${USER}.key" --embed-certs=true
  kubectl config set-context "${USER}@${CLUSTER}" --cluster="${CLUSTER}" --user="${USER}"
done

echo "✔ Пользователи dev_sales и security_analyst добавлены в kubeconfig"
