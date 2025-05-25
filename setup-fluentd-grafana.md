# Налаштування моніторингу BeStrong API за допомогою Fluentd та Grafana

Цей документ описує процес встановлення та налаштування моніторингу для BeStrong API з використанням стеку Fluentd-Elasticsearch-Grafana.

## Загальна архітектура

1. **Fluentd** збирає логи з подів Kubernetes
2. **Elasticsearch** зберігає та індексує логи
3. **Grafana** візуалізує дані з метриками та логами

## Встановлення

### Передумови

- Кластер Kubernetes (AKS)
- Налаштований `kubectl` та доступ до кластера
- Встановлений Helm 3

### Встановлення Ingress Controller

Якщо Ingress Controller ще не встановлено, використовуйте наступні команди:

```bash
# Встановлення NGINX Ingress Controller з явно відключеними webhook'ами
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set controller.admissionWebhooks.enabled=false \
  --set-string controller.config.use-forwarded-headers="true" \
  --set-string controller.config.compute-full-forwarded-for="true" \
  --version 4.9.1
```

### Встановлення Cert-Manager

```bash
# Додаємо репозиторій Cert-Manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Встановлюємо Cert-Manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

### Встановлення Elasticsearch

```bash
# Додаємо репозиторій Elastic
helm repo add elastic https://helm.elastic.co
helm repo update

# Створюємо values файл з конфігурацією
cat > elasticsearch-values.yaml << EOF
# Конфігурація з файлу elasticsearch-values.yaml
EOF

# Встановлюємо Elasticsearch
helm install elasticsearch elastic/elasticsearch -f elasticsearch-values.yaml
```

### Встановлення Fluentd

```bash
# Створюємо ConfigMap для Fluentd
kubectl apply -f fluentd-configmap.yaml

# Створюємо RBAC для Fluentd
kubectl apply -f fluentd-rbac.yaml

# Розгортаємо Fluentd як DaemonSet
kubectl apply -f fluentd-deployment.yaml
```

### Встановлення Grafana

```bash
# Додаємо репозиторій Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Створюємо values файл з конфігурацією
cat > grafana-values.yaml << EOF
# Конфігурація з файлу grafana-values.yaml
EOF

# Встановлюємо Grafana
helm install grafana grafana/grafana -f grafana-values.yaml
```

## Конфігурація та використання

### Доступ до Grafana

Отримайте адміністративний пароль:

```bash
kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

Налаштуйте порт-форвардинг:

```bash
kubectl port-forward svc/grafana 3000:80
```

Тепер Grafana доступна за адресою http://localhost:3000

### Налаштування дашбордів

1. Увійдіть в Grafana з логіном `admin` та паролем, отриманим вище
2. Перейдіть до Configuration > Data Sources та додайте Elasticsearch як джерело даних
3. Імпортуйте дашборди з готових шаблонів або створіть власні

## Відомі проблеми та їх вирішення

### Проблема з webhook валідацією Ingress

**Симптоми:**
- Помилки при створенні Ingress-ресурсів
- Повідомлення про помилку валідації admission webhook

**Причина:**
Ingress-nginx налаштовує webhook для валідації Ingress-ресурсів, який може блокувати створення нових ресурсів.

**Рішення:**
1. Встановіть Ingress Controller з явно відключеними webhook'ами:
   ```bash
   helm install nginx-ingress ingress-nginx/ingress-nginx \
     --set controller.admissionWebhooks.enabled=false \
     --version 4.9.1
   ```

2. Якщо webhook вже створено, видаліть його:
   ```bash
   kubectl delete validatingwebhookconfiguration ingress-nginx-admission
   kubectl delete mutatingwebhookconfiguration ingress-nginx-admission
   ```

### Проблема з доступом AKS до ACR

**Симптоми:**
- Помилки `ImagePullBackOff` при спробі завантажити образи з ACR
- Помилки авторизації в логах подів

**Рішення:**
1. Надайте AKS доступ до ACR:
   ```bash
   az aks update -n CLUSTER_NAME -g RESOURCE_GROUP --attach-acr ACR_NAME
   ```

2. Або створіть секрет docker-registry:
   ```bash
   kubectl create secret docker-registry acr-auth \
     --docker-server=REGISTRY_SERVER \
     --docker-username=USERNAME \
     --docker-password=PASSWORD
   ```

### Проблема з TLS сертифікатами

**Симптоми:**
- HTTPS не працює
- Сертифікат не створюється або не застосовується

**Рішення:**
1. Перевірте статус Certificate:
   ```bash
   kubectl get certificate -o wide
   ```

2. Перевірте логи cert-manager:
   ```bash
   kubectl logs -n cert-manager -l app=cert-manager
   ```

3. Створіть самопідписаний ClusterIssuer:
   ```yaml
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: selfsigned-cluster-issuer
   spec:
     selfSigned: {}
   ```

## Поради для стабільного розгортання

1. **Завжди перевіряйте стан компонентів** перед тим, як переходити до наступного кроку розгортання
2. **Використовуйте фіксовані версії** для Helm-чартів замість latest
3. **Документуйте всі зміни** та кроки налаштування для майбутнього використання
4. **Встановіть таймаути** для операцій розгортання, щоб уникнути "зависання" процесу
5. **Налаштуйте моніторинг** самої системи моніторингу для швидкого виявлення проблем

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