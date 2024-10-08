$dscModuleName = 'RenameBuiltinAccount'

# Create mof file
Configuration RenameBuiltinAccount {

  Import-DscResource -Name RenameBuiltinAccount
	
  RenameBuiltinAccount LocalAccount {
    Username    = 'Guest'
    Ensure      = 'Absent'
    NewUsername = 'AzGuest'
  }
}
RenameBuiltinAccount -OutputPath .\

Rename-Item -Path '.\localhost.mof' -NewName ".\$dscModuleName.mof"

# Create a package for Azure policy
$params = @{
  Name          = $dscModuleName
  Configuration = "$dscModuleName.mof"
  Type          = 'AuditandSet'
  Force         = $true
}
New-GuestConfigurationPackage @params

# Creates a new resource group, storage account, and container
$ResourceGroup = 'sbvmtest'
$Location = 'uksouth'
New-AzResourceGroup -Name $ResourceGroup -Location $Location

$storageAccountName = 'automanagestorage'
$blobContainerName = 'machine-configuration'
$newAccountParams = @{
  ResourceGroupname = $ResourceGroup
  Location          = $Location
  Name              = $storageAccountName
  SkuName           = 'Standard_LRS'
}
# Create New Storage Account
$sa = New-AzStorageAccount @newAccountParams
$container = $sa | New-AzStorageContainer -Name $blobContainerName -Permission Blob

# Use Existing Storage Account
$Sa = Get-AzStorageAccount -Name $storageAccountName -ResourceGroupName $ResourceGroup
$container = $sa | Get-AzStorageContainer -Name $blobContainerName

$context = $container.Context

$setParams = @{
  Container = $blobContainerName
  File      = "./$dscModuleName.zip"
  Context   = $context
}
$blob = Set-AzStorageBlobContent @setParams
$contentUri = $blob.ICloudBlob.Uri.AbsoluteUri

$guid = [GUID]::NewGuid()

$PolicyParameterInfo = @(
  @{
    # Policy parameter name (mandatory)
    Name                 = 'Username'
    # Policy parameter display name (mandatory)
    DisplayName          = 'Builtin Account Username.'
    # Policy parameter description (optional)
    Description          = 'Name of the builtin account to be updated.'
    # DSC configuration resource type (mandatory)
    ResourceType         = 'RenameBuiltinAccount'
    # DSC configuration resource id (mandatory)
    ResourceId           = 'LocalAccount'
    # DSC configuration resource property name (mandatory)
    ResourcePropertyName = 'Username'
    # Policy parameter default value (optional)
    DefaultValue         = 'Guest'
    # Policy parameter allowed values (optional)
    AllowedValues        = @('Administrator', 'Guest')
  }
  @{
    # Policy parameter name (mandatory)
    Name                 = 'NewUsername'
    # Policy parameter display name (mandatory)
    DisplayName          = 'New Username for the built-in account.'
    # Policy parameter description (optional)
    Description          = 'New Name of the builtin account.'
    # DSC configuration resource type (mandatory)
    ResourceType         = 'RenameBuiltinAccount'
    # DSC configuration resource id (mandatory)
    ResourceId           = 'LocalAccount'
    # DSC configuration resource property name (mandatory)
    ResourcePropertyName = 'NewUsername'
    # Policy parameter default value (optional)
    DefaultValue         = 'AzGuest'
  })

$PolicyConfig = @{
  PolicyId      = $guid
  ContentUri    = $contentUri
  DisplayName   = 'Local Account Rename'
  Description   = 'My audit policy'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Windows'
  PolicyVersion = '1.0.0'
  Parameter     = $PolicyParameterInfo
}
New-GuestConfigurationPolicy @PolicyConfig

$PolicyConfig2 = @{
  PolicyId      = $guid
  ContentUri    = $contentUri
  DisplayName   = 'Rename Built-In Account'
  Description   = 'Renames the built-in accounts'
  Path          = './policies/deployIfNotExists'
  Platform      = 'Windows'
  PolicyVersion = '1.0.4'
  Mode          = 'ApplyAndAutoCorrect'
  Parameter     = $PolicyParameterInfo
}
New-GuestConfigurationPolicy @PolicyConfig2

# Create the AZ policy for Audit (PolicyConfig)
New-AzPolicyDefinition -Name 'Audit Built-In Account Name' -Description 'Audits the built-in account name' -Policy 'C:\Users\ScottBarrett\Code\dsc\policies\auditIfNotExists\LocalAccount_AuditIfNotExists.json'

# Create the AZ policy for Audit and set (PolicyConfig2)
New-AzPolicyDefinition -Name 'Rename Built-In Account' -Description 'Renames the built-in account if it exists' -Policy 'C:\Users\ScottBarrett\Code\dsc\policies\deployIfNotExists\RenameBuiltinAccount_DeployIfNotExists.json'
Update-AzPolicyDefinition -Name 'LocalAccountDeploy' -Policy 'C:\Users\ScottBarrett\Code\dsc\policies\deployIfNotExists\LocalAccount_DeployIfNotExists.json'
