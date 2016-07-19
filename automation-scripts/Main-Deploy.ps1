#
# Main_Deploy.ps1
#

#cd '~\Desktop\devops\azure-scalable-iaas-master\powershell-scripts'
$resourceGroupLocation = "westus"

## add aad app login
$appCreds = Get-AutomationConnection -Name 'AzureRunAsConnection'

Add-AzureRmAccount -CertificateThumbprint $appCreds.CertificateThumbprint -ApplicationId $appCreds.ApplicationId -ServicePrincipal -TenantId $appCreds.TenantId

.\Deploy-AzureResourceGroup.ps1 -ResourceGroupLocation $resourceGroupLocation -ResourceGroupName "azure-scalable-iaas-tr_test" -Environment "test"
#.\Deploy-AzureResourceGroup.ps1 -ResourceGroupLocation $resourceGroupLocation -ResourceGroupName "azure-scalable-iaas-tr_prod" -Environment "prod"