#
# Main_Deploy.ps1
#

Param(
    [string] $resourceGroupLocation = "westus",
	[string] [Parameter(Mandatory=$true)] $namePrefix,
	#[object] $WebhookData,

	[string] $env,
	[string] $confKeyVaultName,
	[string] $chefValidationKeySecretName,
	[string] $chefServerUrl,
	[string] $chefValidationClientName,
	[string] $adminUsername,
	[string] $adminPasswordSecretName,
    [string] $subscriptionId
)

## add aad app login
#$appCreds = Get-AutomationConnection -Name 'AzureRunAsConnection'
Add-AzureRmAccount #-CertificateThumbprint $appCreds.CertificateThumbprint -ApplicationId $appCreds.ApplicationId -ServicePrincipal -TenantId $appCreds.TenantId
Select-AzureRmSubscription -SubscriptionId $subscriptionId

# parse webhook body
#$webhookBody = $WebhookData.RequestBody | ConvertFrom-Json

$webhookBody = @{}
$webhookBody.environment = $env

if (($webhookBody.environment -eq "test") -or ($webhookBody.environment -eq "prod"))
{
    .\Deploy-AzureResourceGroup.ps1 -ResourceGroupLocation $resourceGroupLocation -ResourceGroupName "azure-scalable-iaas-$namePrefix$($webhookBody.environment)" -Environment $($webhookBody.environment) -namePrefix $namePrefix -confKeyVaultName $confKeyVaultName -chefValidationKeySecretName $chefValidationKeySecretName -chefServerUrl $chefServerUrl -chefValidationClientName $chefValidationClientName -adminUsername $adminUsername -adminPasswordSecretName $adminPasswordSecretName
}
else
{
    Write-Error "ERROR: Specified environment '$($webhookBody.environment)' does not match 'test' or 'prod'."
}