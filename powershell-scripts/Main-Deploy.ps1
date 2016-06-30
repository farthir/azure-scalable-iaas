#
# Main_Deploy.ps1
#

cd '~\Source\Repos\azure-scalable-iaas\powershell-scripts'
$resourceGroupLocation = "northeurope"

Add-AzureRmAccount

.\Deploy-AzureResourceGroup.ps1 -ResourceGroupLocation $resourceGroupLocation -ResourceGroupName "azure-scalable-iaas-tw_test" -Environment "test"
.\Deploy-AzureResourceGroup.ps1 -ResourceGroupLocation $resourceGroupLocation -ResourceGroupName "azure-scalable-iaas-tw_prod" -Environment "prod"

