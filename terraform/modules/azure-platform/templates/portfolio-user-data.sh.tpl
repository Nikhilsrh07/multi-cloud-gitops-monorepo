#!/bin/bash
# $0 portfolio node: installs k3s (single-node Kubernetes) and deploys the
# portfolio app. Image coordinates are injected by Terraform (dynamic data),
# so switching clouds or image tags needs no static edits here.
set -euxo pipefail

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# --- Install k3s if missing ---
if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | sh -
fi

# --- Wait for the node to be ready ---
for i in $(seq 1 30); do
  if kubectl get nodes 2>/dev/null | grep -q " Ready"; then
    break
  fi
  sleep 10
done

# --- Portfolio manifest (image injected by Terraform) ---
mkdir -p /opt/portfolio
cat > /opt/portfolio/app.yaml <<'MANIFEST'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portfolio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: portfolio
  template:
    metadata:
      labels:
        app: portfolio
    spec:
      containers:
        - name: portfolio
          image: "${image_repository}:${image_tag}"
          ports:
            - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 20
            periodSeconds: 20
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: portfolio
spec:
  type: LoadBalancer
  selector:
    app: portfolio
  ports:
    - port: 80
      targetPort: 8080
MANIFEST

kubectl apply -f /opt/portfolio/app.yaml
# Belt and braces: ensure the exact image Terraform rendered (covers re-runs)
kubectl set image deployment/portfolio portfolio="${image_repository}:${image_tag}" || true

echo "Portfolio deployed: ${image_repository}:${image_tag}"
