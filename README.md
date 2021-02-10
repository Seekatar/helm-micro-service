# Helm Chart for MicroService

Test chart for creating a microservice with a deployment, service, configMap, and secret

`override-values.yml` is a sample yaml file for overriding values in `values.yml`

`run.ps1` will run most of the following commands

```PowerShell
# to generate output
helm install . --dry-run  --generate-name --values ..\override-values.yml | Split-HelmDryRun -Outputpath \temp\helm
```

```PowerShell
# to deploy
helm upgrade --install --values .\override-values.yml cas-widget .
```

```PowerShell
# uninstall
helm uninstall cas-widget
```
