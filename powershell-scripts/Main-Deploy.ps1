#
# Main_Deploy.ps1
#

cd '~\Source\Repos\azure-scalable-iaas\powershell-scripts'
$resourceGroupLocation = "northeurope"

.\Deploy-AzureResourceGroup.ps1 -ResourceGroupLocation $resourceGroupLocation -ResourceGroupName "azure-scalable-iaas_test" -Environment "test"
.\Deploy-AzureResourceGroup.ps1 -ResourceGroupLocation $resourceGroupLocation -ResourceGroupName "azure-scalable-iaas" -Environment "prod"