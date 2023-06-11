<#
.SYNOPSIS
Run commands for the Helm Chart for a  service

.PARAMETER Task
One or more Tasks to run, tab complete

.PARAMETER Name
Name of the service, e.g test

.PARAMETER OverrideFile
Help values override file

.PARAMETER Version
Version number used for pack

.PARAMETER Wait
For install, wait for it to complete

.PARAMETER Force
Normally you can only run helm commands if K8s is set to *desktop*, this will allow you to use any context

.PARAMETER FileCompare
When doing a test, a scriptblock that takes two file names and will return true if that match

.PARAMETER TempFolder
When doing a test, the folder for temporary files

.EXAMPLE
.\run.ps1 install -Name test-widget-api -OverrideFile '..\config-values-api.yml'

Create a widget api service using values in config-values-api.yml

.EXAMPLE
.\run.ps1 dry-run -OverrideFile '..\config-values-api.yml' -Name test-widget-api | Split-HelmDryRun -Outputpath \temp\helm

Do a dry run and split the manifests up for comparing to ./templates

Get with this:
Invoke-WebRequest -OutFile .\Split-HelmDryRun.ps1 https://gist.githubusercontent.com/Seekatar/5c14ad85d9d649ca0da9bf8377367ac4/raw/a0c8b4796acd8b1df03fd9ecee6aa282025acf64/Split-HelmDryRun.ps1
. .\Split-HelmDryRun.ps1
#>
param(
    [Parameter(Mandatory)]
    [ValidateSet('install','uninstall','dry-run','lint','package','test')]
    [string[]] $Task,
    [string] $Name,
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string] $OverrideFile,
    [ValidatePattern('\d+\.\d+.\d+')]
    [string] $Version,
    [switch] $Wait,
    [switch] $Force,
    [scriptblock] $FileCompare = { param($left, $right) fc.exe $left $right > $null; return $LASTEXITCODE -eq 0 },
    [string] $TempFolder = $env:TMP
)

function exec([Parameter(Mandatory)] [string] $taskName,
              [Parameter(Mandatory)] [ScriptBlock] $scriptBlock,
              [string] $WorkingDirectory ) {

    try {
        if ($WorkingDirectory) { Push-Location $WorkingDirectory }
        & $scriptBlock
        if ($LASTEXITCODE -ne 0) { throw "Task '$taskName' exited with $LASTEXITCODE" }
    } finally {
        if ($WorkingDirectory) { Pop-Location}
    }
}

$TempFolder = Resolve-Path $TempFolder

if (!(Get-Command helm) -or !(Get-Command kubectl)) {
    Write-Warning "helm and kubectl must be installed and in path (or an alias)"
    return
}
if (!$Force -and ((kubectl config current-context) -notlike '*desktop*' )) {
    Write-Warning "Current K8s context not *desktop* use -Force to skip this check"
    return
}

foreach ($t in $Task) {
    switch ($t) {
        'install' {
            if (!$OverrideFile -or !$Name) {
                Write-Warning "OverrideFile and Name are required for $t"
            } else {
                $parms = @()
                if ($Wait) {
                    $parms += "--wait" # default wait is 5m0s
                }
                exec $t { helm upgrade --install --values $OverrideFile $Name . @parms} -workingdir $PSScriptRoot/src
            }
        }
        'uninstall' {
            if (!$Name) {
                Write-Warning "Name is required for $t"
            } else {
                exec $t { helm uninstall $Name }
            }
        }
        'dry-run' {
            if (!$OverrideFile -or !$Name) {
                Write-Warning "OverrideFile and Name are required for $t"
            } else {
                exec $t { helm upgrade --install --dry-run --values $OverrideFile $Name . } -WorkingDirectory $PSScriptRoot/src
            }
        }
        'test' {
            exec $t {
                Get-Item ../tests/*.yaml | ForEach-Object {
                    $valuesFile = $_
                    $outputFile = Join-Path $TempFolder $valuesFile.name
                    $compareFile = Join-Path "../tests/output" $valuesFile.name
                    Remove-Item $outputFile -ErrorAction Ignore
                    helm install . --dry-run --generate-name --values $valuesFile | ForEach-Object {
                        ($_ -replace "chart-\d+","chart-0000000000") -replace "LAST DEPLOYED: .*","LAST DEPLOYED: NEVER"
                    } | Out-File $outputFile -Append
                    if (!(Invoke-Command -ScriptBlock $FileCompare -ArgumentList $compareFile,$outputFile)) {
                        Write-Warning "Diff between $compareFile and $outputFile"
                    } else {
                        Write-Information "OK $valuesFile" -InformationAction Continue
                    }
                }
            } -WorkingDirectory $PSScriptRoot/src
        }
        'lint' {
            exec $t { helm lint . --values .\lint-values.yaml } -WorkingDirectory $PSScriptRoot/src
        }
        'package' {
            if (!$Version) {
                Write-Warning "Version is required for $t"
            } else {
                exec $t { helm package . --app-version $Version --version $Version } -WorkingDirectory $PSScriptRoot/src
            }
        }
        Default {}
    }
}

