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
.\New-HelmValuesFile.ps1  -CI -AppName cas-billingest-poller `
                        -NodeSelector nonprod `
                        -ServiceAccountName ocr-devjob-user `
                        -TargetPort 8080 `
                        -ConfigMapProperties @"
                        TEST = 123
                        YO = "test"
"@                      -secretProperties @"
                        secret = be quite
                        shh = moreQuiet
"@

Pretty typical manifest creation using defaults for most everything.

.EXAMPLE
$outFolder = "c:\temp\helm"
$env:BUILD_BUILDID='0.1.7'
.\New-HelmValuesFile.ps1  -CI -AppName cas-bill `
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

.EXAMPLE
$outFolder = "c:\temp\helm"
$env:BUILD_BUILDID='0.1.7'
.\New-HelmValuesFile.ps1  -CI -AppName cas-billimage `
                        -NodeSelector reliancedev `
                        -SecurityContext 33 `
                        -TargetPort 8080 `
                        -Volumes @"
                            [
                                {
                                "vol": "//172.31.2.125/Share01/Images/",
                                "path": "/ais-stage01/Share01/Images/",
                                "secret": "nas-reliance-cifs-secret",
                                "dmode": "0444",
                                "fmode": "0444",
                                "ver": "1.0"
                                }
                            ]
"@

Create a manifest with volumes

.EXAMPLE
$outFolder = "c:\temp\helm"
$env:BUILD_BUILDID='0.1.7'
.\New-HelmValuesFile.ps1  -CI -AppName cas-billimage `
                        -NodeSelector 'node-role: worker-nas' `
                        -TargetPort 8080 `
                        -Cpu 1 -Memory 123Gi `
                        -Volumes @"
                            [
                                {
                                "hostPath": "/ais-stage01/Share03/Images/"
                                }
                            ]
"@

Create a manifest with volumes for AWS, with Cpu and Memory non-default

.EXAMPLE
$outFolder = "c:\temp\helm"
$env:BUILD_BUILDID='0.1.7'
.\New-HelmValuesFile.ps1 -AppName cas-webhook `
                        -Port 80 `
                        -TargetPort 8080

Create the webhook manifest for running locally (no -CI and no nodeselector)

.EXAMPLE
$outFolder = "c:\temp\helm"
$env:BUILD_BUILDID='0.1.7'
.\New-HelmValuesFile.ps1  -CI -AppName cas-nginx `
                        -Port 443 `
                        -NodePort 31100 `
                        -ContainerPort 443 `
                        -LivenessUrl /health/nginx-ingress/live `
                        -ReadyUrl /health/nginx-ingress/ready `
                        -ImageName ccc-cas-nginx:1.0.28 `
                        -NodeSelector reliancedev `
                        -Secret "" `
                        -LivenessLimits 60,15,15 `
                        -ReadyLimits 60,60,60

Create the probably least standard config file for NGINX that exposes a NodePort and has non-default several values.

.EXAMPLE
$outFolder = "c:\temp\helm"
$env:BUILD_BUILDID='0.1.7'
.\New-HelmValuesFile.ps1 `
                        -AppName vue-ui `
                        -CI `
                        -Secret '' `
                        -LivenessUrl 'fp-ui/health/live' `
                        -ReadyUrl 'fp-ui/health/ready' `
                        -Port 80 `
                        -ImageName 'ccc.casfp.ui:1.2.14' `
                        -NodeSelector 'reliancedev' `
                        -TargetPort 8080

Create the FP Vue UI manifest

.EXAMPLE
$valuesFile = New-TemporaryFile
$outputFolder = "c:\temp\helm"

.\New-HelmValuesFile.ps1 -AppName cas-widget-api `
                        -TargetPort 8080 `
                        -ImageName ccc-cas-widget-api:latest `
                        -ConfigMapProperties @"
  OktaGroup__Issuer = https://devauth.cccis.com/oauth2/ausuuegs4xj8jvCxX0h7
  OktaGroup__Authority = https://devauth.cccis.com/oauth2/austmi6vw4xVXKnrv0h7
  OktaScope__Issuer = "https://devauth.cccis.com/oauth2/austmi6vw4xVXKnrv0h7"
  OktaScope__Authority = "https://devauth.cccis.com/oauth2/austmi6vw4xVXKnrv0h7"
  ActiveMq__Host = "host.docker.internal"
  ActiveMq__Username = "service"
  ASPNETCORE_URLS = "http://+:8080"
"@                      -secretProperties "ActiveMq__Password = ...." |
   Out-File $valuesFile -Encoding ascii

.\run.ps1 dry-run -OverrideFile $valuesFile -Name cas-widget-api | Split-HelmDryRun -Outputpath $OutputFolder

#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $AppName,
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
  $configMap.GetEnumerator() | ForEach-Object {
      $configMapYaml += "  $($_.key): $($_.value)`n"
  }
}

$secretYaml = ""
if ($secretProperties) {
  $secrets = ConvertFrom-StringData $secretProperties
  $secretYaml = "secrets:`n"
  Write-Verbose ($secrets.gettype())
  Write-Verbose ($secrets | out-string)
  $secrets.GetEnumerator() | ForEach-Object {
    $secretYaml += "  $($_.key): `"$($_.value)`"`n"
  }
}

$volumesYaml = ""
if ($volumesJson) {
  $volumesYaml = "volumes:`n$volumesJson"
}

$SecurityContextYaml = ""
if ($SecurityContext) {
  $SecurityContextYaml = @"
podSecurityContext:
  runAsUser: $SecurityContext
  runAsGroup: $SecurityContext
  fsGroup: $SecurityContext
"@
}
$tolerations = ""
if ($NodeSelector) {
  if ($NodeSelector -like '*:*') {
    $tolerations = "{key: `"$(($nodeSelector -split ':')[1].Trim())`", operator: `"Exists`" }"
  } else {
    $NodeSelector = "env: `"$NodeSelector`""
  }
}
if (!$CI) {
  # local deployment
  $Registry = ""
  $pullPolicy = "Never"
  $ImageName = ($ImageName -split ':')[0] + ':latest'
} else {
  $pullPolicy = "IfNotPresent"
}


# ------------------------------------
Write-Output @"
serviceName: $appName

deployFlow: false

image:
  name: $(($imageName -split ':')[0])
  tag: $(($imageName -split ':')[1])
  repository: $registry
  pullPolicy: $pullPolicy

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

$SecurityContextYaml

resources:
  requests:
    cpu: $CpuRequest
    memory: $MemoryRequest

nodeSelector: {$NodeSelector}
tolerations: [$tolerations]
"@
