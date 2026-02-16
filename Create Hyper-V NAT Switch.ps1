# 1. Ask for user input
$switchName = Read-Host "Enter the name for the Hyper-V Switch"
$ipPrefix = Read-Host "Enter the IP range in CIDR notation (e.g., 192.168.10.0/24)"
$gatewayIP = Read-Host "Enter the Gateway IP (e.g., 192.168.10.1)"

# 2. Create the Internal Virtual Switch
Write-Host "Creating Internal Switch: $switchName..." -ForegroundColor Cyan
New-VMSwitch -Name $switchName -SwitchType Internal

# 3. Identify the Interface Index of the new switch
$interfaceIndex = (Get-NetAdapter -Name "vEthernet ($switchName)").ifIndex

# 4. Assign the Gateway IP to the Virtual Adapter on the Host
Write-Host "Assigning Gateway IP $gatewayIP to the interface..." -ForegroundColor Cyan
New-NetIPAddress -IPAddress $gatewayIP -PrefixLength ($ipPrefix.Split('/')[1]) -InterfaceIndex $interfaceIndex

# 5. Create the NAT Network
Write-Host "Configuring NAT for range $ipPrefix..." -ForegroundColor Cyan
New-NetNat -Name "NAT_$switchName" -InternalIPInterfaceAddressPrefix $ipPrefix

Write-Host "Success! Switch '$switchName' is ready for use." -ForegroundColor Green