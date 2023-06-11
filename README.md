# Helm Chart for a MicroService

This is a Helm Chart for creating a microservice with a Kubernetes deployment, service, configMap, and secret. It works best with a service created from the [dotnet template]()

## Installing Helm

Helm is just a single executable and requires no installation. Get Helm from [here](https://github.com/helm/helm/releases )

## Using this Chart

To create a chart for a service called `test-widget-service`

1. In your `build` folder, create a new chart and remove the sample templates.

    ```PowerShell
    helm create test-widget-service
    cd test-widget-service
    rmdir templates
    ```

1. Edit `Chart.yaml`, add a dependency for this Chart

    ```yaml
    dependencies:
    - name: test/test-service
      version: "~1.x"
      repository: "https://seekatar.github.io/helm-micro-service/"
    ```

1. Edit `values.yaml` to override value in the dependent chart
1. `helm dependency build`
1. `helm install test-widget-service . --set test-service.serviceName=test-widget-service`

## Using this Repo

You can build and test the chart locally before deploying it. Use `dry-run` to make sure it works, and then use `test` to compare against a baseline. To update the baseline files in tests/output simply run test with a TempFolder of /tests/output

You need Docker, Kubernetes, and Helm installed, and should have the current K8s context set to local Docker.

`run.ps1` will run most of the following commands has snippets to run most commands you need.

| Task      | Description                                                           | Required Params    |
| --------- | --------------------------------------------------------------------- | ------------------ |
| install   | installs the helm template locally                                    | OverrideFile, Name |
| uninstall | uninstalls the helm template locally                                  | Name               |
| uninstall | uninstalls the helm template locally                                  | Name               |
| dry-run   | does a dry run for testing and comparing                              | OverrideFile, Name |
| test      | does a dry run on each values file in ./test and compares to baseline |                    |
| lint      | lints the chart                                                       |                    |
| package   | package up the chart in a zip                                         | Version            |

For test, it will write to the -TempFolder, which defaults to $env:TMP, and will compare files using the scriptblock -FileCompare which defaults to calling fc.exe