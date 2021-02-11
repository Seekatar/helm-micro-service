<#
.SYNOPSIS
Run commands for the Helm Chart for a Casualty service

.PARAMETER Task
One or more Tasks to run, tab complete

.PARAMETER Name
Name of the service, e.g cas

.PARAMETER OverrideFile
Help values override file

.EXAMPLE
.\run.ps1 install -Name cas-widget-api -OverrideFile '..\config-values-api.yml'

Create a widget api service using values in config-values-api.yml

.EXAMPLE
.\run.ps1 dry-run -OverrideFile '..\config-values-api.yml' -Name cas-widget-api | Split-HelmDryRun -Outputpath \temp\helm

Do a dry run and split the manifests up for comparing to ./templates

Get Split-HelmDryRun from https://gist.githubusercontent.com/Seekatar/5c14ad85d9d649ca0da9bf8377367ac4/raw/a0c8b4796acd8b1df03fd9ecee6aa282025acf64/Split-HelmDryRun.ps1
#>
param(
    [Parameter(Mandatory)]
    [ValidateSet('install','uninstall','dry-run','lint','package')]
    [string[]] $Task,
    [string] $Name,
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string] $OverrideFile,
    [ValidatePattern('\d+\.\d+.\d+')]
    [string] $Version,
    [switch] $Wait
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
                exec $t { helm upgrade --install --values $OverrideFile $Name . @parms} -workingdir $PSScriptRoot
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
                exec $t { helm upgrade --install --dry-run --values $OverrideFile $Name --set deployFlow=false . } -WorkingDirectory $PSScriptRoot
            }
        }
        'lint' {
            exec $t { helm lint . } -WorkingDirectory $PSScriptRoot
        }
        'package' {
            if (!$Version) {
                Write-Warning "Version is required for $t"
            } else {
                exec $t { helm package . --app-version $Version --version $Version } -WorkingDirectory $PSScriptRoot
            }
        }
        Default {}
    }
}

