#
# Main_Deploy.ps1
#

cd '~\Source\Repos\azure-scalable-iaas\powershell-scripts'
$resourceGroupLocation = "northeurope"

Add-AzureRmAccount

.\Deploy-AzureResourceGroup.ps1 -ResourceGroupLocation $resourceGroupLocation -ResourceGroupName "azure-scalable-iaas_test" -Environment "test"
.\Deploy-AzureResourceGroup.ps1 -ResourceGroupLocation $resourceGroupLocation -ResourceGroupName "azure-scalable-iaas_prod" -Environment "prod"

