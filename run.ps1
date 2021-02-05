
param(
    [ValidateSet('install','uninstall','dry-run','lint')]
    [string[]] $Task,
    [string] $name = 'cas-widget-api',
    [string] $overrideFile = '..\config-values-api.yml'
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
            exec $t { helm upgrade --install --values $overrideFile $name . } -workingdir $PSScriptRoot
        }
        'uninstall' {
            exec $t { helm uninstall $name }
        }
        'dry-run' {
            exec $t { helm install . --dry-run  --generate-name --values $overrideFile | ..\Split-Debug.ps1 -Outputpath \temp\helm } -WorkingDirectory $PSScriptRoot
        }
        'lint' {
            exec $t { helm lint . } -WorkingDirectory $PSScriptRoot
        }
        Default {}
    }
}

