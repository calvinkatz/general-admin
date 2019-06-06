$cpu_load_limit = 0.5 # CPU usage limit 0.0-1.0 (%)
$mem_load_limit = 0.8 # MEM usage limit 0.0-1.0 (%)
$vm_slot_limit = 10   # VM count limit (#)

function Get-VMHostLoad {
    param(
        # VMHost Object
        [Parameter(Mandatory=$true)]
        $VMHost
    )
    $vmhost_obj = New-Object -TypeName PSObject
    $vmhost_obj | Add-Member -MemberType NoteProperty -Name cpuLoad -Value ($vmhost.CpuUsageMhz / $vmhost.CpuTotalMhz)
    $vmhost_obj | Add-Member -MemberType NoteProperty -Name memLoad -Value ($vmhost.MemoryUsageMB / $vmhost.MemoryTotalMB)
    $vmhost_obj | Add-Member -MemberType NoteProperty -Name vmSlots -Value ($vmhost | Get-VM).Count
    return $vmhost_obj
}

$cluster_list = Get-Cluster

foreach($cluster in $cluster_list) {
    $host_list = $cluster | Get-VMHost
    $host_load_list = @()

    foreach($vmhost in $host_list) {
        $host_load_list += Get-VMHostLoad $vmhost
    }
}

# Balance Memory
# Move 

# Balance CPU

# Balance VM Slots
