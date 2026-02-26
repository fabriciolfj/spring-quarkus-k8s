mvn clean package \
  -Dquarkus.kubernetes.deploy=true \
  -DskipTests \
  -Dquarkus.container-image.username=fabricio211 \
  -Dquarkus.container-image.registry=docker.io
  -Dquarkus.package.type=mutable-jar;



  # a serviceAccount do pod é "example-quarkus-k8s-ch1"
  kubectl create role configmap-reader \
    --verb=get,list,watch \
    --resource=configmaps

  kubectl create rolebinding configmap-reader-binding \
    --role=configmap-reader \
    --serviceaccount=default:example-quarkus-k8s-ch1