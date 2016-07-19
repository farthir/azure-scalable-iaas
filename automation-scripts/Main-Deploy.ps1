#
# Main_Deploy.ps1
#

Param(
    [string] $resourceGroupLocation = "westus",
	[string] [Parameter(Mandatory=$true)] $namePrefix,
	[object] $WebhookData
)

## add aad app login
$appCreds = Get-AutomationConnection -Name 'AzureRunAsConnection'
Add-AzureRmAccount -CertificateThumbprint $appCreds.CertificateThumbprint -ApplicationId $appCreds.ApplicationId -ServicePrincipal -TenantId $appCreds.TenantId

# parse webhook body
$webhookBody = $WebhookData.RequestBody | ConvertFrom-Json

if (($webhookBody.environment -eq "test") -or ($webhookBody.environment -eq "prod"))
{
    #.\Deploy-AzureResourceGroup.ps1 -ResourceGroupLocation $resourceGroupLocation -ResourceGroupName "azure-scalable-iaas-$namePrefix$Environment" -Environment $Environment
}
else
{
    Write-Error "ERROR: Specified environment '$($webhookBody.environment)' does not match 'test' or 'prod'."
}