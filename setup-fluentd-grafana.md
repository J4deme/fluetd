# Setting up Fluentd for BeStrong API logs collection and Grafana integration

## Prerequisites
- Kubernetes cluster with Helm installed
- Access to kubectl

## Step 1: Install Elasticsearch via Helm

```bash
# Add Elastic repository
helm repo add elastic https://helm.elastic.co
helm repo update

# Install Elasticsearch
helm install elasticsearch elastic/elasticsearch -f elasticsearch-values.yaml
```

## Step 2: Configure Fluentd

```bash
# Apply RBAC for Fluentd
kubectl apply -f fluentd-rbac.yaml

# Create ConfigMap for Fluentd configuration
kubectl apply -f fluentd-configmap.yaml

# Run Fluentd as DaemonSet
kubectl apply -f fluentd-deployment.yaml
```

## Step 3: Configure Grafana for log visualization

```bash
# Add Grafana repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install or update Grafana with our settings
helm upgrade --install grafana grafana/grafana -f grafana-values.yaml
```

## Step 4: Verify setup

1. Check pod status:
```bash
kubectl get pods
```

2. Check Fluentd logs:
```bash
kubectl logs -l app=fluentd
```

3. Access Grafana:
```bash
# Get Grafana admin password
kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port forwarding to access Grafana (if needed)
kubectl port-forward svc/grafana 3000:80
```

4. Open Grafana at http://localhost:3000 or via Ingress URL (grafana.128.251.178.137.nip.io)

5. Logs should be available through the "BeStrong API Logs" dashboard

## Additional Information

If you are using Istio, you can also configure log collection through Istio by adding additional settings to Fluentd:

```yaml
# Add to fluent.conf configuration for Istio logs
<source>
  @type tail
  path /var/log/containers/istio-*.log
  pos_file /var/log/fluentd-istio.log.pos
  tag kubernetes.istio.*
  read_from_head true
  <parse>
    @type json
    time_format %Y-%m-%dT%H:%M:%S.%NZ
  </parse>
</source>
```

This configuration will allow you to collect logs from the BeStrong API and display them in Grafana using Elasticsearch. 