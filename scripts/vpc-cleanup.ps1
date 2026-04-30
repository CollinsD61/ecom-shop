param(
  [Parameter(Mandatory = $true)]
  [string]$VpcId,
  [string]$Region,
  [string]$Profile,
  [switch]$Delete,
  [switch]$DeleteEks
)

Set-StrictMode -Version Latest

function Get-AwsBaseArgs {
  $args = @()
  if ($Region) { $args += @("--region", $Region) }
  if ($Profile) { $args += @("--profile", $Profile) }
  return $args
}

function Invoke-AwsJson {
  param([string[]]$CliArgs)
  $baseArgs = Get-AwsBaseArgs
  $output = & aws @baseArgs @CliArgs --output json
  if ($LASTEXITCODE -ne 0) { throw "AWS CLI failed: aws $($CliArgs -join ' ')" }
  return $output | ConvertFrom-Json
}

function Invoke-Aws {
  param([string[]]$CliArgs)
  $baseArgs = Get-AwsBaseArgs
  $null = & aws @baseArgs @CliArgs
  if ($LASTEXITCODE -ne 0) { throw "AWS CLI failed: aws $($CliArgs -join ' ')" }
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
  throw "AWS CLI not found. Install and configure it before running this script."
}

Write-Host "Inspecting dependencies in VPC $VpcId" -ForegroundColor Cyan

$enis = Invoke-AwsJson @(
  "ec2", "describe-network-interfaces",
  "--filters", "Name=vpc-id,Values=$VpcId"
)
$eniList = @($enis.NetworkInterfaces)
$eniIds = @($eniList | ForEach-Object { $_.NetworkInterfaceId })
$eniIdSet = [System.Collections.Generic.HashSet[string]]::new()
foreach ($eniId in $eniIds) { $null = $eniIdSet.Add($eniId) }

$nat = Invoke-AwsJson @(
  "ec2", "describe-nat-gateways",
  "--filter", "Name=vpc-id,Values=$VpcId"
)
$natGateways = @($nat.NatGateways)

$lbAll = Invoke-AwsJson @("elbv2", "describe-load-balancers")
$loadBalancers = @($lbAll.LoadBalancers | Where-Object { $_.VpcId -eq $VpcId })

$vpce = Invoke-AwsJson @(
  "ec2", "describe-vpc-endpoints",
  "--filters", "Name=vpc-id,Values=$VpcId"
)
$vpcEndpoints = @($vpce.VpcEndpoints)

$addresses = Invoke-AwsJson @(
  "ec2", "describe-addresses",
  "--filters", "Name=domain,Values=vpc"
)
$eipsInVpc = @(
  $addresses.Addresses | Where-Object {
    $_.NetworkInterfaceId -and $eniIdSet.Contains($_.NetworkInterfaceId)
  }
)

Write-Host "NAT Gateways:" -ForegroundColor Yellow
if ($natGateways.Count -eq 0) { Write-Host "  (none)" } else {
  $natGateways | ForEach-Object {
    Write-Host ("  {0}  {1}" -f $_.NatGatewayId, $_.State)
  }
}

Write-Host "Load Balancers:" -ForegroundColor Yellow
if ($loadBalancers.Count -eq 0) { Write-Host "  (none)" } else {
  $loadBalancers | ForEach-Object {
    Write-Host ("  {0}  {1}" -f $_.LoadBalancerName, $_.LoadBalancerArn)
  }
}

Write-Host "VPC Endpoints:" -ForegroundColor Yellow
if ($vpcEndpoints.Count -eq 0) { Write-Host "  (none)" } else {
  $vpcEndpoints | ForEach-Object {
    Write-Host ("  {0}  {1}" -f $_.VpcEndpointId, $_.ServiceName)
  }
}

Write-Host "Elastic IPs mapped in VPC:" -ForegroundColor Yellow
if ($eipsInVpc.Count -eq 0) { Write-Host "  (none)" } else {
  $eipsInVpc | ForEach-Object {
    Write-Host ("  {0}  {1}" -f $_.PublicIp, $_.AllocationId)
  }
}

$eniInUse = @($eniList | Where-Object { $_.Status -ne "available" -or $_.Attachment })
$eniAvailable = @($eniList | Where-Object { $_.Status -eq "available" -and -not $_.Attachment })

Write-Host "Network Interfaces (in-use):" -ForegroundColor Yellow
if ($eniInUse.Count -eq 0) { Write-Host "  (none)" } else {
  $eniInUse | ForEach-Object {
    Write-Host ("  {0}  {1}  {2}" -f $_.NetworkInterfaceId, $_.Status, $_.Description)
  }
}

Write-Host "Network Interfaces (available):" -ForegroundColor Yellow
if ($eniAvailable.Count -eq 0) { Write-Host "  (none)" } else {
  $eniAvailable | ForEach-Object {
    Write-Host ("  {0}  {1}" -f $_.NetworkInterfaceId, $_.Description)
  }
}

if (-not $Delete) {
  Write-Host "" 
  Write-Host "Dry run only. Re-run with -Delete to remove dependencies listed above." -ForegroundColor Cyan
  Write-Host "Example: ./scripts/vpc-cleanup.ps1 -VpcId $VpcId -Delete" -ForegroundColor Cyan
  exit 0
}

Write-Host "" 
Write-Host "Deleting dependencies in VPC $VpcId" -ForegroundColor Red

if ($DeleteEks) {
  Write-Host "" 
  Write-Host "Checking EKS clusters in VPC $VpcId" -ForegroundColor Yellow
  $eksList = Invoke-AwsJson @("eks", "list-clusters")
  $eksClusters = @($eksList.clusters)

  foreach ($clusterName in $eksClusters) {
    $clusterInfo = Invoke-AwsJson @("eks", "describe-cluster", "--name", $clusterName)
    if ($clusterInfo.cluster.resourcesVpcConfig.vpcId -ne $VpcId) { continue }

    Write-Host "EKS cluster matched: $clusterName" -ForegroundColor Yellow
    $nodegroups = Invoke-AwsJson @("eks", "list-nodegroups", "--cluster-name", $clusterName)
    foreach ($ng in @($nodegroups.nodegroups)) {
      Write-Host "Deleting EKS nodegroup $ng" -ForegroundColor Red
      Invoke-Aws @("eks", "delete-nodegroup", "--cluster-name", $clusterName, "--nodegroup-name", $ng)
      Invoke-Aws @("eks", "wait", "nodegroup-deleted", "--cluster-name", $clusterName, "--nodegroup-name", $ng)
    }

    Write-Host "Deleting EKS cluster $clusterName" -ForegroundColor Red
    Invoke-Aws @("eks", "delete-cluster", "--name", $clusterName)
    Invoke-Aws @("eks", "wait", "cluster-deleted", "--name", $clusterName)
  }
}

foreach ($lb in $loadBalancers) {
  Write-Host "Deleting load balancer $($lb.LoadBalancerName)" -ForegroundColor Red
  Invoke-Aws @("elbv2", "delete-load-balancer", "--load-balancer-arn", $lb.LoadBalancerArn)
}

foreach ($ng in $natGateways) {
  Write-Host "Deleting NAT gateway $($ng.NatGatewayId)" -ForegroundColor Red
  Invoke-Aws @("ec2", "delete-nat-gateway", "--nat-gateway-id", $ng.NatGatewayId)
}

foreach ($vp in $vpcEndpoints) {
  Write-Host "Deleting VPC endpoint $($vp.VpcEndpointId)" -ForegroundColor Red
  Invoke-Aws @("ec2", "delete-vpc-endpoints", "--vpc-endpoint-ids", $vp.VpcEndpointId)
}

foreach ($eip in $eipsInVpc) {
  if ($eip.AssociationId) {
    Write-Host "Disassociating EIP $($eip.PublicIp)" -ForegroundColor Red
    Invoke-Aws @("ec2", "disassociate-address", "--association-id", $eip.AssociationId)
  }
  if ($eip.AllocationId) {
    Write-Host "Releasing EIP $($eip.PublicIp)" -ForegroundColor Red
    Invoke-Aws @("ec2", "release-address", "--allocation-id", $eip.AllocationId)
  }
}

foreach ($eni in $eniAvailable) {
  Write-Host "Deleting ENI $($eni.NetworkInterfaceId)" -ForegroundColor Red
  Invoke-Aws @("ec2", "delete-network-interface", "--network-interface-id", $eni.NetworkInterfaceId)
}

Write-Host "" 
Write-Host "Dependency cleanup finished. Re-run: terraform destroy" -ForegroundColor Cyan
