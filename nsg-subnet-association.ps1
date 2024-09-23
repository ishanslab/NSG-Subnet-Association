<#
.SYNOPSIS
This script logs into an Azure subscription, retrieves all virtual networks, and ensures that each subnet has a Network Security Group (NSG) associated with it. If a subnet does not have an NSG, a default NSG is created and associated with the subnet.

.PARAMETER Subid
The subscription ID to log into and operate on.

.PARAMETER subnet_to_exclude
An optional array of subnet names to exclude from NSG association. Default subnets to exclude are "GatewaySubnet", "AzureBastionSubnet", "AzureFirewallSubnet", "AzureFirewallManagementSubnet", and "RouteServerSubnet".

.DESCRIPTION
This script performs the following steps:
1. Logs into the specified Azure subscription.
2. Retrieves all virtual networks in the subscription.
3. Iterates through each subnet in each virtual network.
4. Checks if the subnet has an NSG associated with it.
5. If the subnet does not have an NSG and is not in the exclusion list, creates a default NSG and associates it with the subnet.
6. Generates a report of the subnets that were modified.

.EXAMPLE
.\nsg-subnet-association.ps1 -Subid "your-subscription-id"

This example logs into the specified subscription and ensures all subnets have an NSG associated with them, excluding the default subnets.

.EXAMPLE
.\nsg-subnet-association.ps1 -Subid "your-subscription-id" -subnet_to_exclude @("CustomSubnet1", "CustomSubnet2")

This example logs into the specified subscription and ensures all subnets have an NSG associated with them, excluding the default subnets and the custom subnets "CustomSubnet1" and "CustomSubnet2".

.NOTES
- Requires Azure PowerShell Az module.
- The script will throw an error if it fails to log into the subscription or if it encounters issues while processing virtual networks or subnets.
- Author: Ishan
- Date: 2021-09-30
- Version: 1.0
#>

#------------------------------------------------------------------------------
#
#
# THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
# WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#
#------------------------------------------------------------------------------

Param(
    [Parameter(Mandatory = $true)]
    [String]$Subid,
    [parameter(Mandatory = $false)]
    [array]$subnet_to_exclude
)

try {
    "Logging in to Azure..."

    $getsub = (Get-AzSubscription -SubscriptionId $Subid)

    if ($getsub.SubscriptionId -ne $Subid) {
    
        Connect-AzAccount -Subscription $Subid
        start-sleep -seconds 30
        $sub = Select-AzSubscription -SubscriptionId $Subid 
    
        Write-Output "Selected Subscription: $($sub.name)"
    }
    else {
        Write-Output "Subscription already logged in: $($getsub.Name)"
    }
    
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

$vnets = Get-AzVirtualNetwork

$subnets_to_exclude = @("GatewaySubnet", "AzureBastionSubnet", "AzureFirewallSubnet", "AzureFirewallManagementSubnet", "RouteServerSubnet")

if ($subnet_to_exclude) {
    $subnets_to_exclude += $subnet_to_exclude
}

$subnet_report = @()

foreach ($vnet in $vnets) {
    try {
        $subnets = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet
        foreach ($subnet in $subnets) {
            try {
                $random = Get-Random -Minimum 100 -Maximum 999
                if ($null -eq $subnet.NetworkSecurityGroup -and $subnets_to_exclude -notcontains $($subnet.Name)) {

                    Write-Host "Missing NSG for Subnet: $($subnet.Name) in VNet: $($vnet.Name). Creating Default NSG..."
                    $new_nsg = New-AzNetworkSecurityGroup -ResourceGroupName $vnet.ResourceGroupName -Location $vnet.Location -Name "Default-NSG-$($subnet.Name)-$random"
                    Write-Host "Created NSG: $($new_nsg.Name). Associating NSG with Subnet..."
                    $subnet.NetworkSecurityGroup = $new_nsg
                    Set-AzVirtualNetwork -VirtualNetwork $vnet -ErrorAction Stop | Out-Null

                    $subnet_report += [PSCustomObject]@{
                        VNet    = $vnet.Name
                        Subnet  = $subnet.Name
                        New_NSG = $($new_nsg.Name)
                    }
                }
            }
            catch {
                Write-Error "Error processing subnet $($subnet.Name) in VNet $($vnet.Name): $_" 
                $subnet_report += [PSCustomObject]@{
                    VNet    = $vnet.Name
                    Subnet  = $subnet.Name
                    New_NSG = "Failed to associate NSG"
                }
            }
        }
    }
    catch {
        Write-Error "Error processing VNet $($vnet.Name): $_" 
    }
}

if (!($subnet_report)) {
    Write-Output "No subnets were modified since all subnets already had NSG associated, or there were no subnets present."
}
else {
    write-host "Updated Subnet Report:" 
    Write-Output $subnet_report
}
