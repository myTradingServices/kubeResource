#!/bin/bash

minikube start --memory=max --cpus=max --driver=docker;

eval "$(minikube docker-env)";

echo "Bilding docker images into minikube...";

cd /home/andreishyrakanau/projects/project2/priceProvider && docker build -t price-provider .;
cd .. && cd ./priceService && docker build -t price-service .;
cd .. && cd ./chartService && docker build -t chart-service .;
cd .. && cd ./positionService && docker build -t position-service .;
cd ..;

eval "$(minikube docker-env -u)";

cd ./kubeResource && kubectl apply -f postgres.yaml;
kubectl apply -f kafka-zookeeper.yaml;
kubectl apply -f redis.yaml;

echo "Waiting for postgres to complete...";

kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s;
kubectl apply -f flyway-migrations.yaml
kubectl apply -f pgadmin.yaml;

echo "Waiting for kafka-zookeeper to complete...";

kubectl wait --for=condition=ready pod -l app=kafka-zookeeper --timeout=120s;
kubectl apply -f price-provider.yaml;

echo "Waiting for redis and price-provider to complete...";

kubectl wait --for=condition=ready pod -l app=redis --timeout=120s;
kubectl wait --for=condition=ready pod -l app=price-provider --timeout=120s;
kubectl apply -f price-service.yaml;

echo "Waiting for migrations and price-service to complete...";

kubectl wait --for=condition=ready pod -l app=price-service --timeout=120s;
kubectl wait --for=condition=complete job/flyway-job --timeout=120s;

sleep 20s;

#kubectl apply -f chart-service.yaml;
#kubectl apply -f position-service.yaml;

echo -e "Script complete! For further information run \"kubectl get all\" and \"kubectl logs deploy/some-service\""