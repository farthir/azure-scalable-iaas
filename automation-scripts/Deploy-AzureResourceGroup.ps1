#Requires -Version 3.0
#Requires -Module AzureRM.Resources
#Requires -Module Azure.Storage

Param(
    [string] [Parameter(Mandatory=$true)] $ResourceGroupLocation,
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
	[string] [Parameter(Mandatory=$true)] $Environment,
	[string] [Parameter(Mandatory=$true)] $namePrefix,
    [switch] $UploadArtifacts,
    [string] $StorageAccountName,
    [string] $StorageContainerName = $ResourceGroupName.ToLowerInvariant() + '-stageartifacts',
    #[string] $TemplateFile = '..\arm-template\Templates\azuredeploy.json',
    #[string] $TemplateParametersFile = "..\arm-template\Templates\azuredeploy.parameters.json",
    [string] $ArtifactStagingDirectory = '..\bin\Debug\staging',
    [string] $DSCSourceFolder = '..\DSC'
)

Import-Module Azure -ErrorAction SilentlyContinue

try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("VSAzureTools-$UI$($host.name)".replace(" ","_"), "2.9")
} catch { }

Set-StrictMode -Version 3

$TemplateUri = "https://raw.githubusercontent.com/farthir/azure-scalable-iaas/$Environment/arm-template/Templates/azuredeploy.json"
$TemplateParametersUri = "https://raw.githubusercontent.com/farthir/azure-scalable-iaas/$Environment/arm-template/Templates/azuredeploy.parameters.json"

# custom functions to create hash table from parameters json for modification of parameters
function Load-Parameters()
{
    $tempParams = "azuredeploy.parameters.json"
    curl $TemplateParametersUri -OutFile $tempParams
    $JsonContent = Get-Content ./$tempParams -Raw | ConvertFrom-Json
    $global:allParameters = Get-HashTableFromParameterFile $JsonContent
}

function ConvertTo-HashTable([PSCustomObject]$o)
{
    $result = @{}
    foreach ($field in ($o | Get-Member -MemberType NoteProperty))
    {
        $result.Add($field.Name, $(Convert-JsonValue $o.$($field.Name)))
    }

    return $result
}

function Convert-JsonValue($v)
{
    # Need to convert the PSCustomObjects that come from ConvertFrom-Json to hashtables, so that the ARM
        # cmdlet can interpret the value correctly, otherwise it gets passed to the template as an XML string.
        if ($v -ne $null)
        {
			if ($v.GetType().Name -eq "Object[]")
			{
                $newV = @()
                foreach($elem in $v)
                {
                    if ($elem.GetType().Name -eq "PSCustomObject")
                    {
                        $newV += (ConvertTo-HashTable $elem)
                    }
                    else
                    {
                        $newV += $elem
                    }
                }
    
                $v = $newV
		    }
			elseif ($v.GetType().Name -eq "PSCustomObject")
			{
				# TODO: This does not appear to work, when there is a top-level complex object there are errors deploying
				$newV = ConvertTo-HashTable $v
				$v = $newV
			}
        }

    if ($v -ne $null -and $v.GetType().Name -eq "Object[]")
	{
		return ,$v
	}
	else
	{
	    return $v
	}
}
function Get-HashTableFromParameterFile($jsonContent)
{
    $hash = New-Object -TypeName Hashtable
    $JsonContent.parameters | Get-Member -Type NoteProperty |  ForEach-Object {
    $hash[$_.Name] = Convert-JsonValue $JsonContent.parameters.$($_.Name).value
    }

    return $hash
}

Load-Parameters

$OptionalParameters = New-Object -TypeName Hashtable
#$TemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateFile))
#$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))

if ($UploadArtifacts) {
    # Convert relative paths to absolute paths if needed
    $ArtifactStagingDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $ArtifactStagingDirectory))
    $DSCSourceFolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $DSCSourceFolder))

    Set-Variable ArtifactsLocationName '_artifactsLocation' -Option ReadOnly -Force
    Set-Variable ArtifactsLocationSasTokenName '_artifactsLocationSasToken' -Option ReadOnly -Force

    $OptionalParameters.Add($ArtifactsLocationName, $null)
    $OptionalParameters.Add($ArtifactsLocationSasTokenName, $null)

    # Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
    $JsonContent = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
    $JsonParameters = $JsonContent | Get-Member -Type NoteProperty | Where-Object {$_.Name -eq "parameters"}

    if ($JsonParameters -eq $null) {
        $JsonParameters = $JsonContent
    }
    else {
        $JsonParameters = $JsonContent.parameters
    }

    $JsonParameters | Get-Member -Type NoteProperty | ForEach-Object {
        $ParameterValue = $JsonParameters | Select-Object -ExpandProperty $_.Name

        if ($_.Name -eq $ArtifactsLocationName -or $_.Name -eq $ArtifactsLocationSasTokenName) {
            $OptionalParameters[$_.Name] = $ParameterValue.value
        }
    }

    # Create DSC configuration archive
    if (Test-Path $DSCSourceFolder) {
        Add-Type -Assembly System.IO.Compression.FileSystem
        $ArchiveFile = Join-Path $ArtifactStagingDirectory "dsc.zip"
        Remove-Item -Path $ArchiveFile -ErrorAction SilentlyContinue
        [System.IO.Compression.ZipFile]::CreateFromDirectory($DSCSourceFolder, $ArchiveFile)
    }

    $StorageAccountContext = (Get-AzureRmStorageAccount | Where-Object{$_.StorageAccountName -eq $StorageAccountName}).Context

    # Generate the value for artifacts location if it is not provided in the parameter file
    $ArtifactsLocation = $OptionalParameters[$ArtifactsLocationName]
    if ($ArtifactsLocation -eq $null) {
        $ArtifactsLocation = $StorageAccountContext.BlobEndPoint + $StorageContainerName
        $OptionalParameters[$ArtifactsLocationName] = $ArtifactsLocation
    }

    # Copy files from the local storage staging location to the storage account container
    New-AzureStorageContainer -Name $StorageContainerName -Context $StorageAccountContext -Permission Container -ErrorAction SilentlyContinue *>&1

    $ArtifactFilePaths = Get-ChildItem $ArtifactStagingDirectory -Recurse -File | ForEach-Object -Process {$_.FullName}
    foreach ($SourcePath in $ArtifactFilePaths) {
        $BlobName = $SourcePath.Substring($ArtifactStagingDirectory.length + 1)
        Set-AzureStorageBlobContent -File $SourcePath -Blob $BlobName -Container $StorageContainerName -Context $StorageAccountContext -Force
    }

    # Generate the value for artifacts location SAS token if it is not provided in the parameter file
    $ArtifactsLocationSasToken = $OptionalParameters[$ArtifactsLocationSasTokenName]
    if ($ArtifactsLocationSasToken -eq $null) {
        # Create a SAS token for the storage container - this gives temporary read-only access to the container
        $ArtifactsLocationSasToken = New-AzureStorageContainerSASToken -Container $StorageContainerName -Context $StorageAccountContext -Permission r -ExpiryTime (Get-Date).AddHours(4)
        $ArtifactsLocationSasToken = ConvertTo-SecureString $ArtifactsLocationSasToken -AsPlainText -Force
        $OptionalParameters[$ArtifactsLocationSasTokenName] = $ArtifactsLocationSasToken
    }
}

# get private parameters
$confKeyVaultName = Get-AutomationVariable -Name 'confKeyVaultName'
$chefValidationKeySecretName = Get-AutomationVariable -Name 'chefValidationKeySecretName'
$chefServerUrl = Get-AutomationVariable -Name 'chefServerUrl'
$chefValidationClientName = Get-AutomationVariable -Name 'chefValidationClientName'
$adminUsername = Get-AutomationVariable -Name 'adminUsername'
$adminPasswordSecretName = Get-AutomationVariable -Name 'adminPasswordSecretName'

# convert to strings as Get-AutomationVariable does not seem to return strings (ResourceGroupDeployment below will error without this)
Write-Host "Converting"
$confKeyVaultName = $confKeyVaultName.ToString()
$chefValidationKeySecretName = $chefValidationKeySecretName.ToString()
$chefServerUrl = $chefServerUrl.ToString()
$chefValidationClientName = $chefValidationClientName.ToString()
$adminUsername = $adminUsername.ToString()
$adminPasswordSecretName = $adminPasswordSecretName.ToString()

# output parameters to host for validation
Write-Host "converted raw"
$confKeyVaultName
$chefValidationKeySecretName
$chefServerUrl
$chefValidationClientName
$adminUsername
$adminPasswordSecretName
	
# get secret parameters
$chefValidationKey = ConvertTo-SecureString -String (Get-AzureKeyVaultSecret -VaultName $confKeyVaultName -Name $chefValidationKeySecretName).SecretValueText -AsPlainText -Force
$adminPassword = ConvertTo-SecureString -String (Get-AzureKeyVaultSecret -VaultName $confKeyVaultName -Name $adminPasswordSecretName).SecretValueText -AsPlainText -Force

# add private and secret parameters for splatting
$global:allParameters["vmssNameAffix"] = $namePrefix + $Environment
$global:allParameters["adminUsername"] = $adminUsername
$global:allParameters["chefServerUrl"] = $chefServerUrl
$global:allParameters["chefValidationClientName"] = $chefValidationClientName
$OptionalParameters.Add("adminPassword", $adminPassword)
$OptionalParameters.Add("chefValidationKey", $chefValidationKey)

# Create or update the resource group using the specified template file and template parameters file
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force -ErrorAction Stop 

New-AzureRmResourceGroupDeployment -Name ('azuredeploy-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
                                   -ResourceGroupName $ResourceGroupName `
                                   -TemplateUri $TemplateUri `
                                   -TemplateParameterObject $global:allParameters `
                                   @OptionalParameters `
                                   -Force -Verbose