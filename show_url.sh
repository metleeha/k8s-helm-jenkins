#!/bin/bash 

export PASSWD=$(kubectl get secret --namespace jenkins-demo demo-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)
export NODE_PORT=$(kubectl get --namespace jenkins-demo -o jsonpath="{.spec.ports[0].nodePort}" services demo-jenkins)
export NODE_IP=$(kubectl get nodes --namespace jenkins-demo -o jsonpath="{.items[0].status.addresses[1].address}")
echo Jenkins url is http://$NODE_IP:$NODE_PORT/login
echo ID is admin
echo admin passwd is $PASSWD