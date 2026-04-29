param(
    [ValidateSet("dev", "prod")]
    [string]$Environment = "dev",
    [string]$CloudflareApiToken,
    [string]$AwsRegion = "ap-southeast-1",
    [string]$ClusterName,
    [int]$ApplyMaxAttempts = 3,
    [switch]$SkipInit,
    [switch]$NoAutoApprove,
    [switch]$FastStart
)

$ErrorActionPreference = "Stop"

# Avoid interactive pagers/prompts in non-interactive automation runs.
$env:AWS_PAGER = ""
$env:TF_IN_AUTOMATION = "true"

# Do not turn native command stderr into terminating PowerShell errors.
# We need to capture Terraform/AWS CLI stderr text and decide fallback logic ourselves.
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$terraformRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $terraformRoot
$tfDir = Join-Path $terraformRoot (Join-Path "environments" $Environment)
$valuesFile = Join-Path $repoRoot (Join-Path "ecom-shop-chart" (Join-Path "values" "$Environment.yaml"))
$envFileCandidates = @(
    (Join-Path $repoRoot ".env.local"),
    (Join-Path $terraformRoot ".env.local")
)

function Get-EnvValueFromFile {
    param(
        [string]$FilePath,
        [string]$VariableName
    )

    foreach ($rawLine in (Get-Content -Path $FilePath)) {
        $line = $rawLine.Trim()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
            continue
        }

        $parts = $line -split '=', 2
        if ($parts.Count -ne 2) {
            continue
        }

        $key = $parts[0].Trim()
        if ($key -ne $VariableName) {
            continue
        }

        $value = $parts[1].Trim()
        if ($value.Length -ge 2) {
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
        }

        return $value
    }

    return $null
}

function Invoke-CapturedCommand {
    param(
        [string]$Command,
        [string[]]$Arguments
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $commandOutput = & $Command @Arguments 2>&1
        $commandExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return @{
        ExitCode = $commandExitCode
        Output   = @($commandOutput)
        Text     = (@($commandOutput) -join "`n")
    }
}

function Get-SecretInfo {
    param(
        [string]$SecretName,
        [string]$Region
    )

    $describe = Invoke-CapturedCommand -Command "aws" -Arguments @(
        "--no-cli-pager", "secretsmanager", "describe-secret", "--secret-id", $SecretName, "--region", $Region, "--output", "json"
    )

    if ($describe.ExitCode -ne 0) {
        $describeText = $describe.Text
        if ($describeText -match "ResourceNotFoundException|could not be found|can't find") {
            return $null
        }

        throw "describe-secret failed for '$SecretName': $describeText"
    }

    if ([string]::IsNullOrWhiteSpace($describe.Text)) {
        return $null
    }

    return ($describe.Output | ConvertFrom-Json)
}

function Restore-ScheduledDeletionSecrets {
    param(
        [string]$TargetEnvironment,
        [string]$Region
    )

    $awsCommand = Get-Command aws -ErrorAction SilentlyContinue
    if (-not $awsCommand) {
        Write-Warning "AWS CLI not found. Skip restoring pending-deletion secrets."
        return
    }

    $secretNames = @(
        "/ecom/$TargetEnvironment/shared/rds",
        "/ecom/$TargetEnvironment/user-service/db",
        "/ecom/$TargetEnvironment/product-service/db",
        "/ecom/$TargetEnvironment/shopping-cart-service/db",
        "/ecom/$TargetEnvironment/user-service/cognito"
    )

    foreach ($secretName in $secretNames) {
        try {
            $secret = Get-SecretInfo -SecretName $secretName -Region $Region
            if ($null -eq $secret) {
                continue
            }

            if ($null -eq $secret.DeletedDate -or [string]::IsNullOrWhiteSpace([string]$secret.DeletedDate)) {
                continue
            }

            Write-Output "Secret '$secretName' is scheduled for deletion. Restoring..."
            $restore = Invoke-CapturedCommand -Command "aws" -Arguments @(
                "--no-cli-pager", "secretsmanager", "restore-secret", "--secret-id", $secretName, "--region", $Region, "--output", "json"
            )

            if ($restore.ExitCode -ne 0) {
                throw "restore-secret command failed: $($restore.Text)"
            }

            Write-Output "Restored secret '$secretName'."
        }
        catch {
            throw "Failed to restore pending-deletion secret '$secretName': $($_.Exception.Message)"
        }
    }
}

function Get-TerraformStateAddresses {
    param(
        [string]$TerraformDir,
        [string]$TargetEnvironment
    )

    $stateListOutput = & terraform "-chdir=$TerraformDir" state list 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "terraform state list failed for '$TargetEnvironment'."
    }

    $stateAddresses = @{}
    foreach ($line in @($stateListOutput)) {
        $address = [string]$line
        if ([string]::IsNullOrWhiteSpace($address)) {
            continue
        }

        $stateAddresses[$address.Trim()] = $true
    }

    return $stateAddresses
}

function Invoke-TerraformImport {
    param(
        [string]$TerraformDir,
        [string]$ResourceAddress,
        [string]$ImportId
    )

    $importAddress = $ResourceAddress -replace '"', '\"'

    $importResult = Invoke-CapturedCommand -Command "terraform" -Arguments @(
        "-chdir=$TerraformDir", "import", "-lock-timeout=30s", "-input=false", $importAddress, $ImportId
    )

    foreach ($line in @($importResult.Output)) {
        Write-Output $line
    }

    return @{
        ExitCode = $importResult.ExitCode
        Text     = $importResult.Text
    }
}

function Import-ExistingEksResourcesToTerraformState {
    param(
        [string]$TargetEnvironment,
        [string]$Region,
        [string]$TerraformDir,
        [string]$TargetClusterName,
        [hashtable]$StateAddresses
    )

    $awsCommand = Get-Command aws -ErrorAction SilentlyContinue
    if (-not $awsCommand) {
        Write-Warning "AWS CLI not found. Skip importing existing EKS resources into Terraform state."
        return
    }

    $addonAddressMap = [ordered]@{
        "module.eks.aws_eks_addon.vpc_cni"    = "vpc-cni"
        "module.eks.aws_eks_addon.coredns"    = "coredns"
        "module.eks.aws_eks_addon.kube_proxy" = "kube-proxy"
    }

    $clusterAddress = "module.eks.aws_eks_cluster.this"
    $nodeGroupAddress = "module.eks.aws_eks_node_group.this"

    $hasAllEksAddresses = $StateAddresses.ContainsKey($clusterAddress) -and $StateAddresses.ContainsKey($nodeGroupAddress)
    if ($hasAllEksAddresses) {
        $hasAllEksAddresses = ($addonAddressMap.Keys | Where-Object { -not $StateAddresses.ContainsKey($_) }).Count -eq 0
    }

    if ($hasAllEksAddresses) {
        Write-Output "EKS resources already present in Terraform state. Skip EKS reconciliation."
        return
    }

    $clusterExists = $false
    $clusterStatus = $null

    $clusterDescribe = Invoke-CapturedCommand -Command "aws" -Arguments @(
        "--no-cli-pager", "eks", "describe-cluster", "--name", $TargetClusterName, "--region", $Region, "--output", "json"
    )

    if ($clusterDescribe.ExitCode -eq 0) {
        $clusterExists = $true
        try {
            $clusterDescribeData = $clusterDescribe.Output | ConvertFrom-Json
            $clusterStatus = [string]$clusterDescribeData.cluster.status
        }
        catch {
            $clusterStatus = $null
        }
    }
    else {
        $clusterDescribeText = $clusterDescribe.Text
        if ($clusterDescribeText -notmatch "ResourceNotFoundException") {
            throw "describe-cluster failed for '$TargetClusterName': $clusterDescribeText"
        }
    }

    if (-not $stateAddresses.ContainsKey($clusterAddress) -and $clusterExists) {
        if (-not [string]::IsNullOrWhiteSpace($clusterStatus) -and $clusterStatus -ne "ACTIVE") {
            if ($clusterStatus -in @("CREATING", "UPDATING")) {
                Write-Output "EKS cluster '$TargetClusterName' is '$clusterStatus'. Waiting until ACTIVE before import..."

                $wait = Invoke-CapturedCommand -Command "aws" -Arguments @(
                    "--no-cli-pager", "eks", "wait", "cluster-active", "--name", $TargetClusterName, "--region", $Region
                )

                foreach ($line in @($wait.Output)) {
                    if (-not [string]::IsNullOrWhiteSpace([string]$line)) {
                        Write-Output $line
                    }
                }

                if ($wait.ExitCode -ne 0) {
                    throw "wait cluster-active failed for '$TargetClusterName'."
                }

                $clusterDescribe = Invoke-CapturedCommand -Command "aws" -Arguments @(
                    "--no-cli-pager", "eks", "describe-cluster", "--name", $TargetClusterName, "--region", $Region, "--output", "json"
                )

                if ($clusterDescribe.ExitCode -ne 0) {
                    throw "describe-cluster failed for '$TargetClusterName' after wait."
                }

                try {
                    $clusterDescribeData = $clusterDescribe.Output | ConvertFrom-Json
                    $clusterStatus = [string]$clusterDescribeData.cluster.status
                }
                catch {
                    $clusterStatus = $null
                }
            }
            else {
                throw "EKS cluster '$TargetClusterName' is in unexpected status '$clusterStatus'."
            }
        }

        if ($clusterStatus -ne "ACTIVE") {
            throw "EKS cluster '$TargetClusterName' is not ACTIVE yet (status: '$clusterStatus')."
        }

        Write-Output "EKS cluster '$TargetClusterName' exists but is missing in Terraform state. Importing '$clusterAddress'..."
        $clusterImport = Invoke-TerraformImport -TerraformDir $TerraformDir -ResourceAddress $clusterAddress -ImportId $TargetClusterName
        if ($clusterImport.ExitCode -ne 0) {
            throw "terraform import failed for '$clusterAddress' ($TargetClusterName)."
        }
        $StateAddresses[$clusterAddress] = $true
    }

    if (-not $clusterExists -and -not $StateAddresses.ContainsKey($clusterAddress)) {
        return
    }

    $nodeGroupName = "$TargetEnvironment-node-group"

    if (-not $StateAddresses.ContainsKey($nodeGroupAddress)) {
        $nodeGroupDescribe = Invoke-CapturedCommand -Command "aws" -Arguments @(
            "--no-cli-pager", "eks", "describe-nodegroup", "--cluster-name", $TargetClusterName,
            "--nodegroup-name", $nodeGroupName, "--region", $Region, "--output", "json"
        )

        if ($nodeGroupDescribe.ExitCode -eq 0) {
            $nodeGroupImportId = "${TargetClusterName}:$nodeGroupName"
            Write-Output "EKS node group '$nodeGroupName' exists but is missing in Terraform state. Importing '$nodeGroupAddress'..."
            $nodeGroupImport = Invoke-TerraformImport -TerraformDir $TerraformDir -ResourceAddress $nodeGroupAddress -ImportId $nodeGroupImportId
            if ($nodeGroupImport.ExitCode -ne 0) {
                throw "terraform import failed for '$nodeGroupAddress' ($nodeGroupImportId)."
            }
            $StateAddresses[$nodeGroupAddress] = $true
        }
        elseif ($nodeGroupDescribe.Text -notmatch "ResourceNotFoundException") {
            throw "describe-nodegroup failed for '$nodeGroupName': $($nodeGroupDescribe.Text)"
        }
    }

    $addons = Invoke-CapturedCommand -Command "aws" -Arguments @(
        "--no-cli-pager", "eks", "list-addons", "--cluster-name", $TargetClusterName, "--region", $Region,
        "--query", "addons", "--output", "text"
    )

    if ($addons.ExitCode -eq 0) {
        $existingAddons = @(($addons.Text -split '\s+') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        foreach ($addonAddress in $addonAddressMap.Keys) {
            if ($StateAddresses.ContainsKey($addonAddress)) {
                continue
            }

            $addonName = $addonAddressMap[$addonAddress]
            if (-not ($existingAddons -contains $addonName)) {
                continue
            }

            $addonImportId = "${TargetClusterName}:$addonName"
            Write-Output "EKS addon '$addonName' exists but is missing in Terraform state. Importing '$addonAddress'..."
            $addonImport = Invoke-TerraformImport -TerraformDir $TerraformDir -ResourceAddress $addonAddress -ImportId $addonImportId
            if ($addonImport.ExitCode -ne 0) {
                throw "terraform import failed for '$addonAddress' ($addonImportId)."
            }
            $StateAddresses[$addonAddress] = $true
        }
    }
    elseif ($addons.Text -notmatch "ResourceNotFoundException") {
        throw "list-addons failed for cluster '$TargetClusterName': $($addons.Text)"
    }
}

function Import-ExistingSecretsToTerraformState {
    param(
        [string]$TargetEnvironment,
        [string]$Region,
        [string]$TerraformDir,
        [hashtable]$StateAddresses
    )

    $awsCommand = Get-Command aws -ErrorAction SilentlyContinue
    if (-not $awsCommand) {
        Write-Warning "AWS CLI not found. Skip importing existing secrets into Terraform state."
        return
    }

    $resourceToSecretMap = [ordered]@{
        'module.secrets.aws_secretsmanager_secret.shared_rds'                                 = "/ecom/$TargetEnvironment/shared/rds"
        'module.secrets.aws_secretsmanager_secret.service_db["user-service"]'               = "/ecom/$TargetEnvironment/user-service/db"
        'module.secrets.aws_secretsmanager_secret.service_db["product-service"]'            = "/ecom/$TargetEnvironment/product-service/db"
        'module.secrets.aws_secretsmanager_secret.service_db["shopping-cart-service"]'      = "/ecom/$TargetEnvironment/shopping-cart-service/db"
        'module.secrets.aws_secretsmanager_secret.cognito'                                    = "/ecom/$TargetEnvironment/user-service/cognito"
    }

    $missingSecretAddresses = $resourceToSecretMap.Keys | Where-Object { -not $StateAddresses.ContainsKey($_) }
    if ($missingSecretAddresses.Count -eq 0) {
        Write-Output "Secrets already present in Terraform state. Skip secret reconciliation."
        return
    }

    foreach ($resourceAddress in $resourceToSecretMap.Keys) {
        if ($StateAddresses.ContainsKey($resourceAddress)) {
            continue
        }

        $secretName = $resourceToSecretMap[$resourceAddress]
        $secret = Get-SecretInfo -SecretName $secretName -Region $Region
        if ($null -eq $secret) {
            continue
        }

        Write-Output "Secret '$secretName' already exists but is missing in Terraform state. Importing '$resourceAddress'..."
        $secretImport = Invoke-TerraformImport -TerraformDir $TerraformDir -ResourceAddress $resourceAddress -ImportId $secretName

        if ($secretImport.ExitCode -eq 0) {
            continue
        }

        $importText = $secretImport.Text
        $providerConfigIssue = $importText -match "Invalid provider configuration" -or
            $importText -match "depends on values that cannot be determined until apply"
        $addressParsingIssue = $importText -match "Index value required" -or
            $importText -match "on <import-address> line 1"

        if (($providerConfigIssue -or $addressParsingIssue) -and $TargetEnvironment -eq "dev") {
            if ($providerConfigIssue) {
                Write-Warning "Import failed due provider configuration dependency. Falling back to recreate secret '$secretName' in dev."
            }
            elseif ($addressParsingIssue) {
                Write-Warning "Import failed due PowerShell parsing of Terraform for_each address. Falling back to recreate secret '$secretName' in dev."
            }

            $deleteResult = Invoke-CapturedCommand -Command "aws" -Arguments @(
                "--no-cli-pager", "secretsmanager", "delete-secret", "--secret-id", $secretName,
                "--force-delete-without-recovery", "--region", $Region, "--output", "json"
            )

            if ($deleteResult.ExitCode -ne 0) {
                throw "Failed to delete existing secret '$secretName' for recreate fallback: $($deleteResult.Text)"
            }

            $deleted = $false
            for ($i = 0; $i -lt 24; $i++) {
                $existingAfterDelete = Get-SecretInfo -SecretName $secretName -Region $Region
                if ($null -eq $existingAfterDelete) {
                    $deleted = $true
                    break
                }

                Start-Sleep -Seconds 5
            }

            if (-not $deleted) {
                throw "Secret '$secretName' was not deleted in time for recreate fallback."
            }

            Write-Output "Deleted '$secretName'. Terraform apply will recreate it."
            continue
        }

        throw "terraform import failed for '$resourceAddress' ($secretName)."
    }
}

function Invoke-TerraformApplyWithRetry {
    param(
        [string[]]$TerraformArgs,
        [string]$TargetEnvironment,
        [int]$MaxAttempts
    )

    if ($MaxAttempts -lt 1) {
        $MaxAttempts = 1
    }

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        Write-Output "Running terraform apply for '$TargetEnvironment' (attempt $attempt/$MaxAttempts). This can take several minutes (especially RDS/EKS)."

        $applyResult = Invoke-CapturedCommand -Command "terraform" -Arguments $TerraformArgs

        foreach ($line in @($applyResult.Output)) {
            Write-Output $line
        }

        if ($applyResult.ExitCode -eq 0) {
            return
        }

        $applyText = $applyResult.Text
        $transientNetworkIssue = $applyText -match "no such host" -or
            $applyText -match "Temporary failure in name resolution" -or
            $applyText -match "i/o timeout" -or
            $applyText -match "TLS handshake timeout" -or
            $applyText -match "connection reset by peer"

        if ($transientNetworkIssue -and $attempt -lt $MaxAttempts) {
            Write-Warning "Terraform apply failed due transient network/DNS issue. Retrying in 15 seconds..."
            Start-Sleep -Seconds 15
            continue
        }

        throw "terraform apply failed for '$TargetEnvironment'."
    }
}

if (-not (Test-Path $tfDir)) {
    throw "Terraform environment directory not found: $tfDir"
}

$effectiveClusterName = if ([string]::IsNullOrWhiteSpace($ClusterName)) { "$Environment-ecom-cluster" } else { $ClusterName }

$previousToken = $env:TF_VAR_cloudflare_api_token
$tokenWasOverridden = $false

try {
    if (-not [string]::IsNullOrWhiteSpace($CloudflareApiToken)) {
        $env:TF_VAR_cloudflare_api_token = $CloudflareApiToken
        $tokenWasOverridden = $true
    }

    if ([string]::IsNullOrWhiteSpace($env:TF_VAR_cloudflare_api_token)) {
        foreach ($envFile in $envFileCandidates) {
            if (-not (Test-Path $envFile)) {
                continue
            }

            $tokenFromFile = Get-EnvValueFromFile -FilePath $envFile -VariableName "TF_VAR_cloudflare_api_token"
            if (-not [string]::IsNullOrWhiteSpace($tokenFromFile)) {
                $env:TF_VAR_cloudflare_api_token = $tokenFromFile
                $tokenWasOverridden = $true
                Write-Output "Loaded TF_VAR_cloudflare_api_token from $envFile"
                break
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($env:TF_VAR_cloudflare_api_token)) {
        throw "Missing Cloudflare token. Set TF_VAR_cloudflare_api_token, pass -CloudflareApiToken, or put TF_VAR_cloudflare_api_token in .env.local."
    }

    if ($FastStart) {
        Write-Warning "FastStart enabled: skipping recovery/import reconciliation steps to start apply faster."
    }
    else {
        # Recover Secrets Manager secrets that are pending deletion after a recent destroy.
        # Without this step, Terraform create with the same secret name will fail.
        Restore-ScheduledDeletionSecrets -TargetEnvironment $Environment -Region $AwsRegion
    }

    if (-not $SkipInit) {
        & terraform -chdir="$tfDir" init -reconfigure -input=false
        if ($LASTEXITCODE -ne 0) {
            throw "terraform init failed for '$Environment'."
        }
    }

    if (-not $FastStart) {
        $stateAddresses = Get-TerraformStateAddresses -TerraformDir $tfDir -TargetEnvironment $Environment

        Write-Output "Checking/importing existing EKS resources into Terraform state..."
        Import-ExistingEksResourcesToTerraformState -TargetEnvironment $Environment -Region $AwsRegion -TerraformDir $tfDir -TargetClusterName $effectiveClusterName -StateAddresses $stateAddresses

        Write-Output "Checking/importing existing Secrets Manager resources into Terraform state..."
        Import-ExistingSecretsToTerraformState -TargetEnvironment $Environment -Region $AwsRegion -TerraformDir $tfDir -StateAddresses $stateAddresses
    }

    $applyArgs = @("-chdir=$tfDir", "apply", "-input=false")
    $applyArgs += "-lock-timeout=30s"
    if (-not $NoAutoApprove) {
        $applyArgs += "-auto-approve"
    }

    Invoke-TerraformApplyWithRetry -TerraformArgs $applyArgs -TargetEnvironment $Environment -MaxAttempts $ApplyMaxAttempts

    & (Join-Path $PSScriptRoot "sync-cognito-annotation-to-helm.ps1") -Environments @($Environment) -FailOnSkip

    Write-Output "Terraform apply + Cognito annotation sync completed for '$Environment'."
    Write-Output "Updated values file: $valuesFile"
}
finally {
    if ($tokenWasOverridden) {
        if ([string]::IsNullOrWhiteSpace($previousToken)) {
            Remove-Item Env:TF_VAR_cloudflare_api_token -ErrorAction SilentlyContinue
        }
        else {
            $env:TF_VAR_cloudflare_api_token = $previousToken
        }
    }
}
  