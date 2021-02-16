# Helm Chart for MicroService

This is a Helm Chart for creating a Casualty microservice with a deployment, service, configMap, and secret.

## Installing Helm

Helm is just a single executable and requires no installation. Get Helm from [here](https://github.com/helm/helm/releases )

## Using this Chart

To create a chart for a service called `cas-widget-service`

1. In your `build` folder, create a new chart and remove the sample templates.

    ```PowerShell
    helm create cas-widget-service
    cd cas-widget-service
    rmdir templates
    ```

1. Edit `Chart.yaml`, add a dependency for this Chart

    ```yaml
    dependencies:
    - name: ccc/cas-service
      version: "~1.x"
      repository: "https://seekatar.github.io/helm-micro-service/"
    ```

1. Edit `values.yaml` to override value in the dependent chart
1. `helm dependency build`
1. `helm install cas-widget-service . --set serviceName=cas-widget-service`

## This Repo

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
