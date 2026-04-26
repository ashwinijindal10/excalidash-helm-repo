# ExcaliDash Helm Chart

This chart packages [ExcaliDash](https://github.com/ZimengXiong/ExcaliDash) for Kubernetes with production-oriented defaults and an operator-friendly values model.

It supports two deployment styles:

- `singleDeployment: true`: frontend and backend run as two containers in one pod.
- `singleDeployment: false`: frontend and backend run in separate Deployments.

## Why this chart exists

The upstream app is still beta and its backend has important operational constraints:

- the default database is SQLite
- backend state for collaboration is process-local
- upstream recommends careful reverse proxy handling
- fixed secrets are strongly recommended for portability and stable sessions

This chart leans into those realities instead of pretending the app is horizontally safe when it is not.

## Opinionated defaults

- backend replicas stay at `1` unless you explicitly opt into unsafe scaling
- a Secret is created automatically and preserves generated JWT/CSRF values across upgrades
- a PVC is created for backend SQLite data by default
- ingress defaults are Traefik-friendly
- backend outbound update checks are disabled by default

## Install from Helm repo

```bash
helm repo add excalidash https://ashwinijindal10.github.io/excalidash-helm-repo/charts
helm repo update
helm search repo excalidash
```

Install the packaged chart:

```bash
helm upgrade --install excalidash excalidash/excalidash \
  --namespace excalidash \
  --create-namespace \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=excalidash.example.com \
  --set backend.env.FRONTEND_URL=https://excalidash.example.com
```

## Quick start from local checkout

```bash
helm upgrade --install excalidash . \
  --namespace excalidash \
  --create-namespace \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=excalidash.example.com \
  --set backend.env.FRONTEND_URL=https://excalidash.example.com
```

## Traefik example

```yaml
ingress:
  enabled: true
  className: traefik
  hosts:
    - host: excalidash.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: excalidash-tls
      hosts:
        - excalidash.example.com
  traefik:
    entrypoints:
      - websecure
    tls: true
    middlewares:
      - excalidash-security-headers@kubernetescrd

backend:
  env:
    FRONTEND_URL: https://excalidash.example.com
    TRUST_PROXY: "1"
    ENFORCE_HTTPS_REDIRECT: "true"
```

## Split mode example

```yaml
singleDeployment: false

frontend:
  replicaCount: 2

backend:
  replicaCount: 1
```

## Combined mode example

```yaml
singleDeployment: true

combined:
  replicaCount: 1
```

## Useful values

- `secret.extraStringData`: add extra secret-backed env vars like `OIDC_CLIENT_SECRET`
- `backend.env`: main backend configuration surface
- `frontend.extraEnv` and `backend.extraEnv`: add extra env vars or `valueFrom`
- `frontend.envFrom` and `backend.envFrom`: attach ConfigMaps or additional Secrets
- `backend.persistence.*`: SQLite volume settings
- `frontend.service.*` and `backend.service.*`: Service tuning
- `ingress.*`: Ingress and Traefik annotations

## Secrets with Helm

The chart injects the configured Secret into the backend container with `envFrom`.

For upstream ExcaliDash, the important production keys are `JWT_SECRET` and `CSRF_SECRET`. `BOOTSTRAP_ADMIN_KEY` is not part of the upstream production example and is not required by this chart.

If you want Helm to create and manage the Secret:

```yaml
secret:
  create: true
  stringData:
    JWT_SECRET: replace-with-a-long-random-secret
    CSRF_SECRET: replace-with-a-long-random-secret
  extraStringData:
    OIDC_CLIENT_SECRET: replace-me-if-needed
```

If you already have a Kubernetes Secret and want the chart to use it:

```yaml
secret:
  create: false
  name: excalidash-secrets
```

Example Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: excalidash-secrets
  namespace: excalidash
type: Opaque
stringData:
  JWT_SECRET: replace-with-a-long-random-secret
  CSRF_SECRET: replace-with-a-long-random-secret
```

## OIDC example

```yaml
secret:
  extraStringData:
    OIDC_CLIENT_SECRET: replace-me

backend:
  env:
    AUTH_MODE: oidc_enforced
    OIDC_PROVIDER_NAME: Authentik
    OIDC_ISSUER_URL: https://auth.example.com/application/o/excalidash/
    OIDC_CLIENT_ID: excalidash
    OIDC_REDIRECT_URI: https://excalidash.example.com/api/auth/oidc/callback
    OIDC_SCOPES: openid profile email
    FRONTEND_URL: https://excalidash.example.com
```

## Rebuild and publish chart (after changes)

Run these steps when Chart.yaml, templates/, or chart behavior changes.

Bump version in Chart.yaml for each release. Package chart into docs/charts. Rebuild chart index with the same repository base URL. Commit and push.

> update version in Chart.yaml:

```

helm lint . 
helm package . --destination docs/charts 
helm repo index docs/charts --url https://ashwinijindal10.github.io/excalidash-helm-repo/charts

git add . && git commit -m "chore(release): package chart and update index" 
git push origin main
```
## Sources

- [Upstream app repo](https://github.com/ZimengXiong/ExcaliDash)
- [Artifact Hub package](https://artifacthub.io/packages/helm/unxwares/excalidash)
