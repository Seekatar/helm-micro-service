<#
.SYNOPSIS
Replacement for New-K8sManifest.ps1

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

.EXAMPLE
$outFolder = "c:\temp\helm"
$env:BUILD_BUILDID='0.1.7'
.\Install-Helm.ps1  -OutputFolder $outFolder -CI -AppName cas-billingest-poller `
                        -NodeSelector nonprod `
                        -ServiceAccountName ocr-devjob-user `
                        -TargetPort 8080

Pretty typical manifest creation using defaults for most everything.

.EXAMPLE
$outFolder = "c:\temp\helm"
$env:BUILD_BUILDID='0.1.7'
.\Install-Helm.ps1  -OutputFolder $outFolder -CI -AppName cas-bill `
                        -NodeSelector reliancedev `
                        -Volumes @"
                            [
                                {
                                "vol": "//172.31.2.170/Share03/Images/",
                                "path": "/ais-stage01/Share03/Images/",
                                "secret": "nas-reliance-cifs-secret",
                                "dmode": "0444",
                                "fmode": "0444",
                                "ver": "1.0"
                                }
                            ]
"@ `
                        -TargetPort 8080


Create a manifest with volumes
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $AppName,
    [string] $OutputFolder,
    [string] $NodeSelector,
    [string] $VolumesJson,
    [switch] $CI,
    [string] $ServiceAccountName,
    [ValidateRange(1,64000)]
    [int]$Port = 80,
    [ValidateRange(1,64000)]
    [int] $TargetPort = $Port,
    [ValidateRange(1,64000)]
    [int] $ContainerPort = $TargetPort,
    [ValidateRange(0,64000)]
    [int] $NodePort,
    [ValidateRange(1,1000)]
    [int] $Replicas = 1,
    [string] $LivenessUrl = "/health/live",
    [string] $ReadyUrl = "/health/ready",
    [string] $Registry = "rulesenginecontainerregistry.azurecr.io",
    [string] $ImageName = "ccc-$AppName-service:$env:BUILD_BUILDID",
    [string] $Secret = "$AppName-secret",
    [ValidateCount(3,3)]
    [int[]] $LivenessLimits = @(10,15,15),
    [ValidateCount(3,3)]
    [int[]] $ReadyLimits = @(45,120,120),
    [int] $SecurityContext,
    [double] $CpuRequest = 0.3,
    [string] $MemoryRequest = "500Mi",
    [string] $configMapProperties,
    [string] $secretProperties
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$serviceType = if ($nodePort) { "NodePort" } else {"ClusterIP" }

$configMapYaml = ""
if ($configMapProperties) {
  $configMap = ConvertFrom-StringData $configMapProperties
  $configMapYaml = "configMap:`n"
  $configMap.Keys | ForEach-Object {
      $configMapYaml += "  ${_}: `"$($_[$_])`"'"
  }
}

$secretYaml = ""
if ($secretProperties) {
  $secret = ConvertFrom-StringData $secretProperties
  $secretYaml = "secret:`n"
  $secret.Keys | ForEach-Object {
      $secretMapYaml += "  ${_}: `"$($_[$_])`"'"
  }
}

$volumesYaml = ""
if ($volumesJson) {
  $volumesYaml = "volumes:`n$volumesJson"
}

$values = @"
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
  port: $targetPort
  liveness:
    url: $livenessUrl
    initialDelaySeconds: $($livenessLimits[0])
    timeoutSeconds: $($livenessLimits[1])
    periodSeconds: $($livenessLimits[2])
  ready:
    url: $readyUrl
    initialDelaySeconds: $($readyLimits[0])
    timeoutSeconds: $($readyLimits[1])
    periodSeconds: $($readyLimits[2])

service:
  type: $serviceType
  port: $port
  targetPort: $targetPort
  nodePort: $nodePort

"@
$valuesFile = New-TemporaryFile
$values | Out-File $valuesFile -Encoding ascii

Write-Verbose "Values written to $valuesFile"

& (Join-Path $PSScriptRoot run.ps1) dry-run -OverrideFile $valuesFile -Name $appName | Split-HelmDryRun -Outputpath $OutputFolder