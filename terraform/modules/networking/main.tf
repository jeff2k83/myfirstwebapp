# Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.environment}-hub-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.hub_vnet_address_space
  tags                = var.tags
}

# Hub Subnets
resource "azurerm_subnet" "firewall" {
  count = var.enable_azure_firewall ? 1 : 0

  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.hub_vnet_address_space[0], 8, 0)]
}

resource "azurerm_subnet" "gateway" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.hub_vnet_address_space[0], 8, 1)]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.hub_vnet_address_space[0], 8, 2)]
}

resource "azurerm_subnet" "shared_services" {
  name                 = "SharedServicesSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.hub_vnet_address_space[0], 8, 3)]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

# Azure Firewall
resource "azurerm_public_ip" "firewall" {
  count = var.enable_azure_firewall ? 1 : 0

  name                = "pip-${var.environment}-firewall-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "hub" {
  count = var.enable_azure_firewall ? 1 : 0

  name                = "afw-${var.environment}-hub-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall[0].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

# Azure Bastion
resource "azurerm_public_ip" "bastion" {
  name                = "pip-${var.environment}-bastion-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "hub" {
  name                = "bas-${var.environment}-hub-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

# VPN Gateway (optional)
resource "azurerm_public_ip" "vpn_gateway" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = "pip-${var.environment}-vpngateway-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = "vgw-${var.environment}-vpn-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  tags                = var.tags

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway[0].id
  }
}

# Spoke Virtual Networks
resource "azurerm_virtual_network" "spoke" {
  for_each = var.spoke_vnets

  name                = "${each.value.name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = each.value.address_space
  tags                = var.tags
}

# Spoke Subnets
resource "azurerm_subnet" "spoke" {
  for_each = merge([
    for spoke_key, spoke in var.spoke_vnets : {
      for subnet_key, subnet in spoke.subnets :
      "${spoke_key}-${subnet_key}" => {
        spoke_key         = spoke_key
        subnet_key        = subnet_key
        address_prefix    = subnet.address_prefix
        service_endpoints = subnet.service_endpoints
        vnet_name         = azurerm_virtual_network.spoke[spoke_key].name
      }
    }
  ]...)

  name                 = each.value.subnet_key
  resource_group_name  = var.resource_group_name
  virtual_network_name = each.value.vnet_name
  address_prefixes     = [each.value.address_prefix]
  service_endpoints    = each.value.service_endpoints
}

# Network Security Groups for Spokes
resource "azurerm_network_security_group" "spoke" {
  for_each = var.spoke_vnets

  name                = "nsg-${each.key}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# VNet Peering: Hub to Spokes
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.spoke_vnets

  name                         = "peer-hub-to-${each.key}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke[each.key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.enable_vpn_gateway
}

# VNet Peering: Spokes to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = var.spoke_vnets

  name                         = "peer-${each.key}-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.spoke[each.key].name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = var.enable_vpn_gateway

  depends_on = [azurerm_virtual_network_gateway.vpn]
}

# Network Watcher
resource "azurerm_network_watcher" "main" {
  name                = "nw-${var.environment}-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
