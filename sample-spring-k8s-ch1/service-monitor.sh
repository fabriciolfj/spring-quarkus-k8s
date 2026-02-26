cat <<EOF | kubectl apply -f -
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
EOF