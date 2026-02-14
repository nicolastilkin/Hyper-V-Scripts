# --- Configuration ---
$ParentDiskPath = "C:\VMs\Tools\Base\BASE-WS2025.vhdx"
$LabLocation    = "C:\VMs\Lab\Lab1"
$SwitchName     = "Private-Switch"

# --- 1. Ask for the VM Name ---
$VMName = Read-Host -Prompt "Please enter the name of the new VM"

# Validate input
if ([string]::IsNullOrWhiteSpace($VMName)) {
    Write-Error "VM Name cannot be empty."
    exit
}

# --- 2. Pre-Flight Checks ---
# Check if Parent Disk exists
if (-not (Test-Path $ParentDiskPath)) {
    Write-Error "Parent Base Disk not found at: $ParentDiskPath"
    exit
}

# Check if the Virtual Switch exists
$SwitchExists = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
if (-not $SwitchExists) {
    Write-Error "Virtual Switch '$SwitchName' was not found. Please create it first."
    exit
}

# --- 3. Prepare Paths ---
# Create a specific folder for this VM
$VMPath = Join-Path -Path $LabLocation -ChildPath $VMName
$DiffDiskPath = Join-Path -Path $VMPath -ChildPath "$VMName.vhdx"

# Create the VM Directory if it doesn't exist
if (-not (Test-Path $VMPath)) {
    New-Item -Path $VMPath -ItemType Directory | Out-Null
    Write-Host "Created directory: $VMPath" -ForegroundColor Cyan
}

# --- 4. Create & Configure Resources ---

try {
    # A. Create the Differential Disk
    Write-Host "Creating Differential Disk..." -ForegroundColor Cyan
    New-VHD -ParentPath $ParentDiskPath -Path $DiffDiskPath -Differencing | Out-Null

    # B. Create the VM (Generation 2)
    Write-Host "Creating Virtual Machine..." -ForegroundColor Cyan
    New-VM -Name $VMName -MemoryStartupBytes 4GB -VHDPath $DiffDiskPath -Path $LabLocation -Generation 2 | Out-Null

    # C. Configure CPU (8 Cores)
    Write-Host "Configuring CPU (8 Cores)..." -ForegroundColor Cyan
    Set-VMProcessor -VMName $VMName -Count 8

    # D. Disable Dynamic Memory
    Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false

    # E. Connect Network Adapter
    Write-Host "Connecting to switch '$SwitchName'..." -ForegroundColor Cyan
    Connect-VMNetworkAdapter -VMName $VMName -SwitchName $SwitchName

    # F. Disable Automatic Checkpoints
    Write-Host "Disabling Automatic Checkpoints..." -ForegroundColor Cyan
    Set-VM -Name $VMName -CheckpointType Disabled

    # --- Success Message ---
    Write-Host "---------------------------------------------"
    Write-Host "VM '$VMName' created successfully!" -ForegroundColor Green
    Write-Host "Location: $VMPath"
    Write-Host "Specs:    8 Cores | 4GB RAM"
    Write-Host "Network:  Connected to '$SwitchName'"
    Write-Host "Checkpoints: Disabled"
    Write-Host "---------------------------------------------"
}
catch {
    Write-Error "An error occurred: $_"
}