#create RG
resource "azurerm_resource_group" "rg" {
  name     = "rg_tf_private_aks"
  location = var.location
}

#create VNet
resource "azurerm_virtual_network" "vnet_aks" {
  name                = "vnet-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.10.0.0/16"]
}

#create Subnet - AKS Cluster
resource "azurerm_subnet" "subnet_aks_cluster" {
  name                 = "subnet-aks-cluster"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_aks.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_private_dns_zone" "dev_zone" {
  name                = "dev.privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet-link-01" {
  name                  = "vnet-link-01"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dev_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet_aks.id
}

#create managed identity
resource "azurerm_user_assigned_identity" "mi_aks" {
  location            = azurerm_resource_group.rg.location
  name                = "mi-aks"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "aks_role_01" {
  scope                = azurerm_subnet.subnet_aks_cluster.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.mi_aks.principal_id
}

resource "azurerm_role_assignment" "aks_role_02" {
  scope                = azurerm_private_dns_zone.dev_zone.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.mi_aks.principal_id
}

#Create AKS Cluster
resource "azurerm_kubernetes_cluster" "aks_private_001" {
  name                = "aks_private_001"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-cluster"
  private_cluster_enabled = true

  # To prevent CIDR collition with the 10.0.0.0/16 Vnet
  network_profile {
    network_plugin     = "azure"
    network_policy = "calico"
  }

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.subnet_aks_cluster.id
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mi_aks.id]
  }

   private_dns_zone_id =  azurerm_private_dns_zone.dev_zone.id
   depends_on = [ azurerm_private_dns_zone.dev_zone, azurerm_role_assignment.aks_role_02 ]

}

