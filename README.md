# Helm Chart for MicroService

Test chart for creating a microservice with a deployment, service, configMap, and secret

`override-values.yml` is a sample yaml file for overriding values in `values.yml`

```PowerShell
# To generate output
helm install . --dry-run  --generate-name --values ..\override-values.yml | ..\Split-Debug.ps1 -Outputpath \temp\helm

# to deploy
helm upgrade --install --values .\override-values.yml cas-widget .
```

```PowerShell
# to get port if nodeport
$NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services cas-widget)
$NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
"http://${NODE_IP}:$NODE_PORT"
```

```PowerShell
# to get port if clusterIP
$POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=cas-widget,app.kubernetes.io/name=cas-widget" -o jsonpath="{.items[0].metadata.name}")
$CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
echo "Visit http://127.0.0.1:8080 to use your application"
kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
```

```PowerShell
# uninstall
helm uninstall cas-widget
```
