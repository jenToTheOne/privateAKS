##
# Create Vnet and subnet for the Bastion VM
##
/*resource "azurerm_virtual_network" "vnet_bastion" {
  name                = "vnet-bastion-demo"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
}
resource "azurerm_subnet" "snet_bastion_vm" {
  name                 = "snet-bastion-demo"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_bastion.name
  address_prefixes     = ["10.1.0.0/24"]
}
resource "azurerm_subnet" "snet_azure_bastion_service" {
  # The subnet name cannot be changed as the azure bastion host depends on the same
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_bastion.name
  address_prefixes     = ["10.1.1.0/24"]
}

##
# Create Vnet peering for the bastion VM to be able to access the cluster Vnet and IPs
##
resource "azurerm_virtual_network_peering" "peering_bastion_cluster" {
  name                      = "peering_bastion_cluster"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_bastion.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_aks.id
}
resource "azurerm_virtual_network_peering" "peering_cluster_bastion" {
  name                      = "peering_cluster_bastion"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_aks.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_bastion.id
}

##
# Create a Bastion VM
##
resource "azurerm_network_interface" "bastion_nic" {
  name                = "nic-bastion"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet_bastion_vm.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm_bastion" {
  name                            = "vm-bastion"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_D2_v2"
  admin_username                  = "adminuser"
  admin_password                  = "azureUser1234"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.bastion_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

##
# Create an Azure Bastion Service to access the Bastion VM
##
resource "azurerm_public_ip" "pip_azure_bastion" {
  name                = "pip-azure-bastion"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_bastion_host" "azure-bastion" {
  name                = "azure-bastion"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.snet_azure_bastion_service.id
    public_ip_address_id = azurerm_public_ip.pip_azure_bastion.id
  }
}

##
# Link the Bastion Vnet to the Private DNS Zone generated to resolve the Server IP from the URL in Kubeconfig
##
resource "azurerm_private_dns_zone_virtual_network_link" "link_bastion_cluster" {
  name = "dnslink-bastion-cluster"
  # The Terraform language does not support user-defined functions, and so only the functions built in to the language are available for use.
  # The below code gets the private dns zone name from the fqdn, by slicing the out dns prefix
  private_dns_zone_name = join(".", slice(split(".", azurerm_kubernetes_cluster.aks_private_001.private_fqdn), 1, length(split(".", azurerm_kubernetes_cluster.aks_private_001.private_fqdn))))
  resource_group_name   = "MC_${azurerm_resource_group.rg.name}_${azurerm_kubernetes_cluster.aks_private_001.name}_${var.location}"
  virtual_network_id    = azurerm_virtual_network.vnet_bastion.id
}*/