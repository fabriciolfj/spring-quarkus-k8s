# Monitoramento com MicroK8s + Prometheus + Spring Boot

## Pré-requisitos

- Ubuntu/Debian com snap instalado
- Docker instalado
- Java 17+
- Maven

---

## 1. Instalação do MicroK8s

```bash
sudo snap install microk8s --classic

# Configurar permissões
sudo usermod -a -G microk8s $USER
sudo chown -R $USER ~/.kube
newgrp microk8s

# Aguardar subir
microk8s status --wait-ready

mkdir -p ~/.kube
microk8s config > ~/.kube/config

```

### Habilitar addons essenciais

```bash
microk8s enable dns
microk8s enable storage
microk8s enable helm3
microk8s enable ingress
microk8s enable metrics-server
microk8s enable registry
```

### Configurar kubectl

```bash
microk8s config > ~/.kube/config
chmod 600 ~/.kube/config

# Aliases úteis
alias kubectl='microk8s kubectl'
alias helm='microk8s helm3'
```

---

## 2. Instalar Stack de Observabilidade (Prometheus + Grafana + Loki + Tempo)

```bash
microk8s enable prometheus
```

O addon instala tudo no namespace `observability`:
- Prometheus
- Grafana
- Alertmanager
- Loki (logs)
- Tempo (tracing)
- kube-state-metrics
- node-exporter

### Acessar os dashboards

```bash
# Prometheus
kubectl port-forward svc/kube-prom-stack-kube-prome-prometheus 9090:9090 -n observability

# Grafana
kubectl port-forward svc/kube-prom-stack-grafana 3000:80 -n observability
# user: admin / senha: admin

# Alertmanager
kubectl port-forward svc/kube-prom-stack-kube-prome-alertmanager 9093:9093 -n observability
```

---

## 3. Preparar a Imagem Docker

### Opção 1 — Usar registry local do MicroK8s (sem push para Docker Hub)

```bash
# habilitar registry local
microk8s enable registry

# build da imagem
docker build -t minha-app:1.0.0 .

# taguear para o registry local (porta 32000)
docker tag minha-app:1.0.0 localhost:32000/minha-app:1.0.0

# push para o registry local
docker push localhost:32000/minha-app:1.0.0
```

No manifesto usar:
```yaml
image: localhost:32000/minha-app:1.0.0
```

### Opção 2 — Importar imagem existente

```bash
docker save minha-app:1.0.0 | microk8s ctr image import -
```

---

## 4. Configurar a Aplicação Spring Boot

### pom.xml

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

### application.properties

```properties
management.endpoints.web.exposure.include=*
management.endpoint.health.show-details=always
management.endpoint.health.probes.enabled=true
management.server.port=8081
```

---

## 5. Manifesto Kubernetes da Aplicação

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minha-app
  namespace: default
  labels:
    app: minha-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: minha-app
  template:
    metadata:
      labels:
        app: minha-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8081"
        prometheus.io/path: "/actuator/prometheus"
    spec:
      containers:
        - name: minha-app
          image: localhost:32000/minha-app:1.0.0
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8080
            - name: management
              containerPort: 8081
          env:
            - name: SERVER_PORT
              value: "8080"
            - name: MANAGEMENT_SERVER_PORT
              value: "8081"
          readinessProbe:
            httpGet:
              path: /actuator/health/readiness
              port: management
            initialDelaySeconds: 20
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /actuator/health/liveness
              port: management
            initialDelaySeconds: 30
            periodSeconds: 15
          startupProbe:
            httpGet:
              path: /actuator/health
              port: management
            initialDelaySeconds: 10
            periodSeconds: 5
            failureThreshold: 20
---
apiVersion: v1
kind: Service
metadata:
  name: minha-app
  namespace: default
  labels:
    app: minha-app
    release: kube-prom-stack    # obrigatório para o ServiceMonitor
spec:
  selector:
    app: minha-app
  ports:
    - name: http
      port: 8080
      targetPort: http
    - name: management
      port: 8081
      targetPort: management
  type: NodePort
```

---

## 6. Criar o ServiceMonitor

O ServiceMonitor instrui o Prometheus a coletar métricas da aplicação.

```yaml
# servicemonitor-minha-app.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: minha-app
  namespace: observability
  labels:
    release: kube-prom-stack
spec:
  selector:
    matchLabels:
      app: minha-app
  endpoints:
    - port: management
      path: /actuator/prometheus
      interval: 30s
  namespaceSelector:
    matchNames:
      - default
```

```bash
kubectl apply -f servicemonitor-minha-app.yaml
```

---

## 7. Verificar

```bash
# verificar pods
kubectl get pods -n default
kubectl get pods -n observability

# verificar ServiceMonitor
kubectl get servicemonitor minha-app -n observability

# verificar targets no Prometheus
kubectl port-forward svc/kube-prom-stack-kube-prome-prometheus 9090:9090 -n observability
# acessar http://localhost:9090/targets
```

---

## Pontos importantes

| Item | Detalhe |
|---|---|
| Namespace do Prometheus | `observability` |
| Label obrigatório no Service | `release: kube-prom-stack` |
| Label obrigatório no ServiceMonitor | `release: kube-prom-stack` |
| Porta management Spring | `8081` |
| Endpoint métricas Spring | `/actuator/prometheus` |
| Endpoint métricas Quarkus | `/q/metrics` |
| Porta management Quarkus | `9000` |

---

## Troubleshooting

### Pod em Pending
```bash
kubectl describe pod <nome-do-pod>
kubectl get events --sort-by='.lastTimestamp'
```

### ServiceMonitor não aparece no Prometheus
- Verificar se o label `release: kube-prom-stack` está no Service
- Verificar se o ServiceMonitor está no namespace `observability`
- Verificar se o `namespaceSelector` aponta para o namespace correto

### Target DOWN
```bash
# testar endpoint de métricas
kubectl port-forward svc/minha-app 8081:8081
curl http://localhost:8081/actuator/prometheus
```
