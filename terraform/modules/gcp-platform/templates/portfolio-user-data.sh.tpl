#!/bin/bash
# $0 portfolio node: installs k3s (single-node Kubernetes) and deploys the
# portfolio app. Image coordinates are injected by Terraform (dynamic data),
# so switching clouds or image tags needs no static edits here.
set -euxo pipefail

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

mkdir -p /var/lib/rancher/k3s/server/manifests
cat > /var/lib/rancher/k3s/server/manifests/traefik-config.yaml <<'TRAEFIK'
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    persistence:
      enabled: true
      size: 128Mi
    certificatesResolvers:
      letsencrypt:
        acme:
          email: "${acme_email}"
          storage: /data/acme.json
          httpChallenge:
            entryPoint: web
    additionalArguments:
      - "--entryPoints.web.http.redirections.entryPoint.to=websecure"
      - "--entryPoints.web.http.redirections.entryPoint.scheme=https"
TRAEFIK

# --- Install k3s if missing ---
if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=metrics-server" sh -
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
              cpu: "50m"
              memory: "96Mi"
            limits:
              cpu: "250m"
              memory: "256Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: portfolio
spec:
  selector:
    app: portfolio
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: portfolio
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.tls.certresolver: letsencrypt
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - "${site_hostname}"
  rules:
    - host: "${site_hostname}"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: portfolio
                port:
                  number: 80
MANIFEST

kubectl apply -f /opt/portfolio/app.yaml

echo "Portfolio deployed: ${image_repository}:${image_tag}"
