@description('Location for the resources.')
param location string = resourceGroup().location

@description('Name for the Virtual Machine.')
param vmName string = 'linux-vm'

@description('User name for the Virtual Machine.')
param adminUsername string

@description('Type of authentication to use on the Virtual Machine.')
@allowed([
  'password'
  'sshPublicKey'
])
param authenticationType string = 'sshPublicKey'

@description('Password or ssh key for the Virtual Machine.')
@secure()
param adminPasswordOrKey string

@description('Size for the Virtual Machine.')
param vmSize string = 'Standard_B2ms'

@description('Determines whether or not a new storage account should be provisioned.')
@allowed([
  'new'
  'existing'
])
param storageNewOrExisting string = 'new'

@description('Name of the storage account')
param storageAccountName string = 'storage${uniqueString(resourceGroup().id)}'

@description('Storage account type')
param storageAccountType string = 'Standard_LRS'

@description('Name of the resource group for the existing storage account')
param storageAccountResourceGroupName string = resourceGroup().name

@description('Determines whether or not a new virtual network should be provisioned.')
@allowed([
  'new'
  'existing'
])
param virtualNetworkNewOrExisting string = 'new'

@description('Name of the virtual network')
param virtualNetworkName string = 'VirtualNetwork'

@description('Address prefix of the virtual network')
param addressPrefixes array = [
  '10.0.0.0/16'
]

@description('Name of the subnet')
param subnetName string = 'default'

@description('Subnet prefix of the virtual network')
param subnetPrefix string = '10.0.0.0/24'

@description('Name of the resource group for the existing virtual network')
param virtualNetworkResourceGroupName string = resourceGroup().name

@description('Determines whether or not a new public ip should be provisioned.')
@allowed([
  'none'
  'new'
  'existing'
])
param publicIpNewOrExisting string = 'new'

@description('Name of the public ip address')
param publicIpName string = 'PublicIp'

@description('DNS of the public ip address for the VM')
param publicIpDns string = 'linux-vm-${uniqueString(resourceGroup().id)}'

@description('Name of the resource group for the public ip address')
param publicIpResourceGroupName string = resourceGroup().name

@description('The size of the data disk to attach to the VM')
param dataDiskSize int = 513

@description('The tier of the data disk to attach to the VM')
param dataDiskTier string = 'P30'

@description('The sku of the data disk to attach to the VM')
param dataDiskSku string = 'Premium_LRS'

@description('The sku of the log disk to attach to the VM')
param logDiskSku string = 'Premium_LRS'

@description('The size of the data disk to attach to the VM')
param logsDiskSize int = 513

@description('The tier of the data disk to attach to the VM')
param logsDiskTier string = 'P30'

@description('The availability zone to pin this VM and disks to')
param availabilityZone string = '1'

@description('Allocation method for the public ip address')
@allowed([
  'Dynamic'
  'Static'
  ''
])
param publicIpAllocationMethod string = 'Dynamic'

@description('Name of the resource group for the public ip address')
@allowed([
  'Basic'
  'Standard'
  ''
])
param publicIpSku string = 'Basic'

@description('The keyvault details for the Key vault creation or access')
param keyVaultNewOrExisting string = 'new'
param keyVaultName string = 'KeyVault${uniqueString(resourceGroup().id)}'
@secure()
param keyVaultUserObjectId string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param _artifactsLocationSasToken string = ''

var nicName = '${vmName}-nic'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var publicIpAddressId = {
  id: resourceId(publicIpResourceGroupName, 'Microsoft.Network/publicIPAddresses', publicIpName)
}
var networkSecurityGroupName = 'nsg-ssh'
var scriptFolder = 'scripts'
var scriptFileName = 'copy.sh'
var scriptArgs = '-a ${uri(_artifactsLocation, '.')} -t "${_artifactsLocationSasToken}" -p ${scriptFolder}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = if (storageNewOrExisting == 'new') {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageAccountType
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-05-01' = if (publicIpNewOrExisting == 'new') {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIpAllocationMethod
    dnsSettings: {
      domainNameLabel: publicIpDns
    }
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-05-01' = if (virtualNetworkNewOrExisting == 'new') {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '22'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-https'
        properties: {
          priority: 1001
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(virtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, subnetName)
          }
          publicIPAddress: ((publicIpNewOrExisting != 'none') ? publicIpAddressId : json('null'))
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
  dependsOn: [
    publicIp
    virtualNetwork

  ]
}

resource vmName_data 'Microsoft.Compute/disks@2022-03-02' = {
  name: '${vmName}-data'
  location: location
  sku: {
    name: dataDiskSku
  }
  properties: {
    burstingEnabled: true
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: dataDiskSize
    osType: 'Linux'
    publicNetworkAccess: 'Disabled'
    tier: dataDiskTier
  }
  zones: [
    availabilityZone
  ]
}

resource vmName_logs 'Microsoft.Compute/disks@2022-03-02' = {
  name: '${vmName}-logs'
  location: location
  sku: {
    name: logDiskSku
  }
  properties: {
    burstingEnabled: true
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: logsDiskSize
    osType: 'Linux'
    publicNetworkAccess: 'Disabled'
    tier: logsDiskTier
  }
  zones: [
    availabilityZone
  ]
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18_04-lts-gen2'
        version: 'latest'
      }
      dataDisks: [
        {
          lun: 1
          caching: 'ReadWrite'
          managedDisk: {
            id: vmName_data.id
          }
          createOption: 'Attach'
        }
        {
          lun: 2
          caching: 'ReadWrite'
          managedDisk: {
            id: vmName_logs.id
          }
          createOption: 'Attach'
        }
      ]
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(resourceId(storageAccountResourceGroupName, 'Microsoft.Storage/storageAccounts/', storageAccountName), '2018-02-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccount

  ]
}

resource vmName_configScript 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  parent: vm
  name: 'configScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(_artifactsLocation, 'scripts/${scriptFileName}${_artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash ${scriptFileName} ${scriptArgs}'
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = if (keyVaultNewOrExisting == 'new') {
  name: keyVaultName
  location: location
  properties: {
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: keyVaultUserObjectId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// resource existingKeyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
//   scope: resourceGroup()
//   name: keyVaultName
// }

// resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   parent: existingKeyVault
//   name: '${vmName}_ssh_key'
//   properties: {
//     value: adminPasswordOrKey
//   }
// }

output ssh_command string = ((publicIpNewOrExisting == 'none') ? 'no public ip, vnet access only' : 'ssh ${adminUsername}@${reference(resourceId(publicIpResourceGroupName, 'Microsoft.Network/publicIPAddresses', publicIpName), '2018-04-01').dnsSettings.fqdn}')
