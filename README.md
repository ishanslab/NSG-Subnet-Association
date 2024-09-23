# NSG-Subnet-Association  

## Introduction  
This script logs into an Azure subscription, retrieves all virtual networks, and ensures that each subnet has a Network Security Group (NSG) associated with it. If a subnet does not have an NSG, a default NSG is created and associated with the subnet.  

This script performs the following steps:  
1. Logs into the specified Azure subscription.
2. Retrieves all virtual networks in the subscription.
3. Iterates through each subnet in each virtual network.
4. Checks if the subnet has an NSG associated with it.
5. If the subnet does not have an NSG and is not in the exclusion list, creates a default NSG and associates it with the subnet.
6. Generates a report of the subnets that were modified.

## Example

```powershell
.\nsg-to-subnet-blog.ps1 -Subid "your-subscription-id"
```

This example logs into the specified subscription and ensures all subnets have an NSG associated with them, excluding the default subnets.

```powershell
.\nsg-to-subnet-blog.ps1 -Subid "your-subscription-id" -subnet_to_exclude @("CustomSubnet1", "CustomSubnet2")

# or

.\nsg-to-subnet-blog.ps1 -Subid "your-subscription-id" -subnet_to_exclude "CustomSubnet1", "CustomSubnet2"
```  

This example logs into the specified subscription and ensures all subnets have an NSG associated with them, excluding the default subnets and the custom subnets "CustomSubnet1" and "CustomSubnet2".  

## Parameters  

Parameter | Type | example 
--- | --- | ---
Subid | String | "your-subscription-id"
subnet_to_exclude | Array | @("CustomSubnet1", "CustomSubnet2")






