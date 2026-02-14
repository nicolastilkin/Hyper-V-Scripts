# Create Hyper-V NAT Switch
# Network: 10.0.0.0/24
# Switch Name: Switch NAT

# Requires Administrator privileges
#Requires -RunAsAdministrator

# Configuration variables
$SwitchName = "Switch NAT"
$NATNetworkName = "NATNetwork"
$NATName = "NATNetwork"
$NetworkPrefix = "10.0.0.0/24"
$GatewayIP = "10.0.0.1"
$PrefixLength = 24

Write-Host "Creating Hyper-V NAT Switch Configuration..." -ForegroundColor Cyan
Write-Host "Switch Name: $SwitchName" -ForegroundColor Yellow
Write-Host "Network: $NetworkPrefix" -ForegroundColor Yellow
Write-Host "Gateway IP: $GatewayIP" -ForegroundColor Yellow
Write-Host ""

# Step 1: Create Internal Virtual Switch
Write-Host "[1/3] Creating Internal Virtual Switch..." -ForegroundColor Green
try {
    $existingSwitch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
    if ($existingSwitch) {
        Write-Host "Switch '$SwitchName' already exists. Skipping creation." -ForegroundColor Yellow
    } else {
        New-VMSwitch -Name $SwitchName -SwitchType Internal | Out-Null
        Write-Host "Internal Virtual Switch created successfully." -ForegroundColor Green
    }
} catch {
    Write-Host "Error creating switch: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Configure IP address on the virtual adapter
Write-Host "[2/3] Configuring IP address on virtual adapter..." -ForegroundColor Green
try {
    $adapter = Get-NetAdapter | Where-Object { $_.Name -like "*$SwitchName*" }
    
    if ($adapter) {
        # Remove existing IP configuration if present
        $existingIP = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if ($existingIP) {
            Write-Host "Removing existing IP configuration..." -ForegroundColor Yellow
            Remove-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        }
        
        # Add new IP configuration
        New-NetIPAddress -IPAddress $GatewayIP -PrefixLength $PrefixLength -InterfaceIndex $adapter.ifIndex | Out-Null
        Write-Host "IP address configured: $GatewayIP/$PrefixLength" -ForegroundColor Green
    } else {
        Write-Host "Error: Virtual adapter not found." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error configuring IP address: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Create NAT network
Write-Host "[3/3] Creating NAT network..." -ForegroundColor Green
try {
    $existingNAT = Get-NetNat -Name $NATName -ErrorAction SilentlyContinue
    if ($existingNAT) {
        Write-Host "NAT '$NATName' already exists. Skipping creation." -ForegroundColor Yellow
    } else {
        New-NetNat -Name $NATName -InternalIPInterfaceAddressPrefix $NetworkPrefix | Out-Null
        Write-Host "NAT network created successfully." -ForegroundColor Green
    }
} catch {
    Write-Host "Error creating NAT: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Hyper-V NAT Switch Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration Summary:" -ForegroundColor Cyan
Write-Host "  Switch Name: $SwitchName" -ForegroundColor White
Write-Host "  Network: $NetworkPrefix" -ForegroundColor White
Write-Host "  Gateway IP: $GatewayIP" -ForegroundColor White
Write-Host "  NAT Name: $NATName" -ForegroundColor White
Write-Host ""
Write-Host "You can now assign VMs to this switch." -ForegroundColor Yellow
Write-Host "VMs should use IP addresses in the range 10.0.0.2 - 10.0.0.254" -ForegroundColor Yellow
Write-Host "with gateway: $GatewayIP" -ForegroundColor Yellow
Write-Host ""