<#
.SYNOPSIS

.PARAMETER appName
Name of the app, e.g. cas-bill, used for names of image, etc.

.PARAMETER environment
Title case environment used in string substitutions of variables, environment, etc. (letter, numbers, _)

.PARAMETER triggeringPipeline
Name of pipeline that triggers this, so can pull artifacts

.PARAMETER configMapProperties
Name = value pairs for configMap

.PARAMETER imageName
Docker image name with tag

.PARAMETER dependsOn
Name of stage this depends on

.PARAMETER secretProperties
Name = value pairs for secret

.PARAMETER variableGroups
variableGroups

.PARAMETER appPrefix
Name used for service connection template and Environment

.PARAMETER serviceAccountName
Optional service account name

.PARAMETER volumesJson
JSON string of array of volumes

.PARAMETER port
Port value, defaults to 80

.PARAMETER targetPort
TargetPort value, defaults to 8080 so can listen in container as non-root

.PARAMETER containerPort
ContainerPort value, defaults to to same as TargetPort

.PARAMETER nodePort
NodePort value, defaults to 0 making it a ClusterIP

.PARAMETER replicas
Number of replicas, defaults to 1

.PARAMETER livenessUrl
Liveness Url defaults to /health/live

.PARAMETER readyUrl
Ready Url defaults to /health/ready

.PARAMETER registry
Container registry, defaults to rulesenginecontainerregistry.azurecr.io

.PARAMETER secret
Secret name, defaults to appName-secret

.PARAMETER livenessLimits
string of comma-delimited InitialDelaySeconds, timeoutSeconds and periodSeconds, defaults to @(10,15,15)

.PARAMETER readyLimits
string of comma-delimited InitialDelaySeconds, timeoutSeconds and periodSeconds, defaults to @(45,120,120)

.PARAMETER aws
Set to append aws to variables file for kube connections
#>
param (
[string] $appName,
[string] $environment,
[string] $triggeringPipeline,
[string] $configMapProperties,
[string] $imageName,
[string] $dependsOn,
[Parameter(Mandatory)]
[string] $secretProperties = 'test = test',
[object] $variableGroups,
[string] $appPrefix,
[string] $serviceAccountName,
[Parameter(Mandatory)]
[string] $volumesJson = '[]',
[Parameter(Mandatory)]
[number] $port = 80,
[Parameter(Mandatory)]
[number] $targetPort = 8080,
[number] $containerPort,
[number] $nodePort,
[Parameter(Mandatory)]
[number] $replicas = 1,
[Parameter(Mandatory)]
[string] $livenessUrl = '/health/live',
[Parameter(Mandatory)]
[string] $readyUrl = '/health/ready',
[Parameter(Mandatory)]
[string] $registry = 'rulesenginecontainerregistry.azurecr.io',
[string] $secret,
[ValidateCount(3,3)]
[int[]] $LivenessLimits = @(10,15,15),
[ValidateCount(3,3)]
[int[]] $ReadyLimits = @(45,120,120)
)

$serviceType = if ($nodePort) { "NodePort" } else {"ClusterIP" }
$configMap = ConvertFrom-StringData $configMapProperties
$secret = ConvertFrom-StringData $secretProperties

$configMapYaml = ""
if ($configMap) {
    $configMapYaml = "configMap:`n"
    $configMap.Keys | ForEach-Object {
        $configMapYaml += "  ${_}: `"$($_[$_])`"'"
    }
}
$secretYaml = ""
if ($secret) {
    $secretYaml = "secret:`n"
    $secret.Keys | ForEach-Object {
        $secretMapYaml += "  ${_}: `"$($_[$_])`"'"
    }
}

$volumesYaml = ""
if ($volumesJson) {
# volumes:
#   - hostPath: /ais-stage01/Share03/Images/
#   - vol: //172.31.2.125/Share01/Images/
#     path: /ais-stage01/Share01/Images/
#     secret: nas-reliance-cifs-secret
#     dmode: "0444"
#     fmode: "0444"
#     ver: "1.0"

}
@"
# Override of default values for Helm template
serviceName: $appName

image:
  name: $(($imageName -split ':')[0])
  tag: $(($imageName -split ':')[1])
  repository: $registry
  pullPolicy: IfNotPresent

$configMapYaml
$secretYaml
$volumesYaml

healthChecks:
  liveness:
    url: $livenessUrl
    initialDelaySeconds: $($livenessLimit[0])
    timeoutSeconds: $($livenessLimit[1])
    periodSeconds: $($livenessLimit[2])
  ready:
    url: $readyUrl
    initialDelaySeconds: $($readyLimit[0])
    timeoutSeconds: $($readyLimit[1])
    periodSeconds: $($readyLimit[2])

service:
  type: $serviceType
  port: $port
  targetPort: $targetPort
  nodePort: $nodePort

"@