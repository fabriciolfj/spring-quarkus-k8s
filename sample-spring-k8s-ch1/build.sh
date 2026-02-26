mvn clean package spring-boot:build-image;
#minikube image load fabricio211/sample-spring-k8s-ch1:1.0.0;
# tag correto
docker tag fabricio211/sample-spring-k8s-ch1:1.0.0 localhost:32000/sample-spring-k8s-ch1:1.0.0

# push
docker push localhost:32000/sample-spring-k8s-ch1:1.0.0

kubectl apply -f sample-spring-k8s-ch1/deployment.yml



