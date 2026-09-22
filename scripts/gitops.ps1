param(
    [ValidateSet('validate', 'plan', 'apply', 'destroy', 'deploy', 'undeploy', 'help')]
    [string]$Action = 'help',
    [string]$VarFile = '',
    [string]$ReleaseName = 'portfolio',
    [string]$Namespace = 'production',
    [string]$ImageRepository = 'nodejs-multi-cloud-app',
    [string]$ImageTag = 'latest',
    [switch]$AutoApprove
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$terraformDir = Join-Path $repoRoot 'terraform\environments\dev'
$chartDir = Join-Path $repoRoot 'helm\my-app'

function Show-Help {
    Write-Host 'Usage: .\scripts\gitops.ps1 -Action <validate|plan|apply|destroy|deploy|undeploy>' -ForegroundColor Cyan
    Write-Host '  deploy   Install or upgrade the portfolio Helm release in the current kube context.' -ForegroundColor Gray
    Write-Host '  undeploy Remove the portfolio Helm release from the current kube context.' -ForegroundColor Gray
    Write-Host '  destroy  Requires -AutoApprove and destroys Terraform-managed infrastructure.' -ForegroundColor Gray
}

function Invoke-Terraform {
    param([string[]]$Arguments)
    & terraform "-chdir=$terraformDir" @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Terraform failed: $($Arguments -join ' ')" }
}

function Invoke-Helm {
    param([string[]]$Arguments)
    & helm @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Helm failed: $($Arguments -join ' ')" }
}

if ($Action -eq 'help') { Show-Help; exit 0 }
if (-not (Test-Path $terraformDir)) { throw "Terraform environment not found: $terraformDir" }

$terraformVars = @()
if ($VarFile) {
    if (-not (Test-Path $VarFile)) { throw "Variable file not found: $VarFile" }
    $terraformVars = @('-var-file', $VarFile)
}

switch ($Action) {
    'validate' {
        Invoke-Terraform -Arguments @('init', '-backend=false')
        Invoke-Terraform -Arguments @('validate')
    }
    'plan' {
        Invoke-Terraform -Arguments @('init', '-backend=false')
        Invoke-Terraform -Arguments (@('plan') + $terraformVars)
    }
    'apply' {
        Invoke-Terraform -Arguments @('init', '-backend=false')
        $applyArgs = @('apply') + $terraformVars
        if ($AutoApprove) { $applyArgs += '-auto-approve' }
        Invoke-Terraform -Arguments $applyArgs
    }
    'destroy' {
        if (-not $AutoApprove) { throw 'Destroy requires -AutoApprove.' }
        Invoke-Terraform -Arguments @('init', '-backend=false')
        Invoke-Terraform -Arguments (@('destroy') + $terraformVars + @('-auto-approve'))
    }
    'deploy' {
        if (-not (Get-Command helm -ErrorAction SilentlyContinue)) { throw 'helm is required for deploy.' }
        Invoke-Helm -Arguments @('upgrade', '--install', $ReleaseName, $chartDir, '--namespace', $Namespace, '--create-namespace', '--set', "image.repository=$ImageRepository", '--set', "image.tag=$ImageTag")
    }
    'undeploy' {
        if (-not (Get-Command helm -ErrorAction SilentlyContinue)) { throw 'helm is required for undeploy.' }
        Invoke-Helm -Arguments @('uninstall', $ReleaseName, '--namespace', $Namespace)
    }
}

Write-Host "Completed action: $Action" -ForegroundColor Green