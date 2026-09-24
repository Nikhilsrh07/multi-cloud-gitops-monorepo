param(
    [ValidateSet('validate', 'plan', 'apply', 'destroy', 'deploy', 'undeploy', 'up', 'help')]
    [string]$Action = 'help',
    [ValidateSet('aws', 'gcp', 'azure')]
    [string]$Cloud = 'gcp',
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment = '',
    [switch]$UseTerragrunt,
    [string]$VarFile = '',
    [string]$ReleaseName = 'portfolio',
    [string]$Namespace = 'production',
    [string]$IngressHost = 'www.nikhil-srh07.com',
    [string]$ImageRepository = 'nodejs-multi-cloud-app',
    [string]$ImageTag = 'latest',
    [switch]$AutoApprove
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$chartDir = Join-Path $repoRoot 'helm\my-app'

function Show-Help {
    Write-Host 'Usage: .\scripts\gitops.ps1 -Action <up|validate|plan|apply|destroy|deploy|undeploy> -Cloud <aws|gcp|azure>' -ForegroundColor Cyan
    Write-Host '  Example: .\scripts\gitops.ps1 -Action plan -Cloud aws' -ForegroundColor Gray
    Write-Host '  Quick start: .\scripts\gitops.ps1 -Action up -Cloud gcp' -ForegroundColor Gray
    Write-Host '  Add -UseTerragrunt to use the shared Terragrunt remote state.' -ForegroundColor Gray
    Write-Host '  deploy   Install or upgrade the portfolio Helm release in the current kube context.' -ForegroundColor Gray
    Write-Host '  undeploy Remove the portfolio Helm release from the current kube context.' -ForegroundColor Gray
    Write-Host '  destroy  Requires -AutoApprove and destroys Terraform-managed infrastructure.' -ForegroundColor Gray
}

function Invoke-Terraform {
    param([string[]]$Arguments)
    & terraform "-chdir=$terraformDir" @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Terraform failed: $($Arguments -join ' ')" }
}

function Invoke-Terragrunt {
    param([string[]]$Arguments)
    if (-not (Get-Command terragrunt -ErrorAction SilentlyContinue)) {
        throw 'terragrunt is required when -UseTerragrunt is specified.'
    }
    $env:TG_CLOUD = $Cloud
    & terragrunt '--working-dir' $terraformDir @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Terragrunt failed: $($Arguments -join ' ')" }
}

function Invoke-Helm {
    param([string[]]$Arguments)
    & helm @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Helm failed: $($Arguments -join ' ')" }
}

function Invoke-Apply {
    $applyArgs = @('apply') + $cloudVar + $terraformVars
    if ($AutoApprove) { $applyArgs += '-auto-approve' }
    if ($UseTerragrunt) {
        Invoke-Terragrunt -Arguments $applyArgs
    }
    else {
        Invoke-Terraform -Arguments @('init', '-backend=false')
        Invoke-Terraform -Arguments $applyArgs
    }
}

function Invoke-Deploy {
    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) { throw 'helm is required for deploy.' }
    Invoke-Helm -Arguments @('upgrade', '--install', $ReleaseName, $chartDir, '--namespace', $Namespace, '--create-namespace', '--set', "image.repository=$ImageRepository", '--set', "image.tag=$ImageTag", '--set', "ingress.host=$IngressHost")
}

if ($Action -eq 'help') { Show-Help; exit 0 }

if (-not $Environment) {
    $Environment = Read-Host 'Environment [dev]'
    if (-not $Environment) { $Environment = 'dev' }
}

if ($Environment -notin @('dev', 'staging', 'prod')) {
    throw 'Environment must be dev, staging, or prod.'
}

$environmentRoot = Join-Path $repoRoot "terraform\environments\$Environment"
$cloudTerraformDir = Join-Path $environmentRoot $Cloud
$terraformDir = if (Test-Path $cloudTerraformDir) { $cloudTerraformDir } else { $environmentRoot }

if (-not (Test-Path $terraformDir)) { throw "Terraform environment not found: $terraformDir" }

$terraformVars = @()
if ($VarFile) {
    if (-not (Test-Path $VarFile)) { throw "Variable file not found: $VarFile" }
    $terraformVars = @('-var-file', $VarFile)
}
$cloudVar = @()
if ($terraformDir -eq $environmentRoot) {
    $cloudVar = @('-var', "cloud=$Cloud")
}
if ($Cloud -eq 'gcp' -and -not $VarFile) {
    $gcpProject = ''
    if (Get-Command gcloud -ErrorAction SilentlyContinue) {
        $gcpProject = (& gcloud config get-value project 2>$null).Trim()
    }
    if ($gcpProject) { $cloudVar = @('-var', "project_id=$gcpProject") }
}
if ($Cloud -eq 'gcp' -and -not ($cloudVar | Where-Object { $_ -like 'project_id=*' })) {
    $gcpProject = $env:GOOGLE_CLOUD_PROJECT
    if (-not $gcpProject) {
        throw 'GCP project is not configured. Run: gcloud config set project <project-id>'
    }
    $cloudVar = @('-var', "project_id=$gcpProject")
}

switch ($Action) {
    'validate' {
        Invoke-Terraform -Arguments @('init', '-backend=false')
        Invoke-Terraform -Arguments @('validate')
    }
    'plan' {
        if ($UseTerragrunt) {
            Invoke-Terragrunt -Arguments (@('plan') + $cloudVar + $terraformVars)
        }
        else {
            Invoke-Terraform -Arguments @('init', '-backend=false')
            Invoke-Terraform -Arguments (@('plan') + $cloudVar + $terraformVars)
        }
    }
    'apply' {
        Invoke-Apply
    }
    'destroy' {
        if (-not $AutoApprove) { throw 'Destroy requires -AutoApprove.' }
        $destroyArgs = @('destroy') + $cloudVar + $terraformVars + @('-auto-approve')
        if ($UseTerragrunt) {
            Invoke-Terragrunt -Arguments $destroyArgs
        }
        else {
            Invoke-Terraform -Arguments @('init', '-backend=false')
            Invoke-Terraform -Arguments $destroyArgs
        }
    }
    'deploy' {
        Invoke-Deploy
    }
    'undeploy' {
        if (-not (Get-Command helm -ErrorAction SilentlyContinue)) { throw 'helm is required for undeploy.' }
        Invoke-Helm -Arguments @('uninstall', $ReleaseName, '--namespace', $Namespace)
    }
    'up' {
        if (-not $AutoApprove) {
            $confirmation = Read-Host "Provision $Cloud/$Environment and deploy Helm to Kubernetes? [y/N]"
            if ($confirmation -notmatch '^(y|yes)$') { throw 'Operation cancelled.' }
        }
        Invoke-Apply
        Invoke-Deploy
    }
}

Write-Host "Completed action: $Action" -ForegroundColor Green