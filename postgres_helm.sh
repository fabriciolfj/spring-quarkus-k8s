helm repo add bitnami https://charts.bitnami.com/bitnami

helm install person-db bitnami/postgresql --set auth.username=quarkus --set auth.database=quarkus