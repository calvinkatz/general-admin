#######################################
##
## Date:     5/31/2019
## Author:   Calvin Kohler-Katz
## Filename: fake-drs.ps1
##
## Description: Emulates VMWare DRS functionality.
##  Assign load limits and vCenter to connect.
##  By default all clusters and VMs are processed.
##
#######################################
<#

Balance memory:
    Rule: MEM deviation <10% and VM moved does not cause deviation to go up.
    Move smallest VM from most loaded host to least observing rule.
    Repeat until rule cannot be satified on initial move.

#>

Import-Module VMware.PowerCLI

$vcenter_server = "vcenter.domain.com"
$cpu_load_limit = 0.5 # CPU usage limit 0.0-1.0 (%)
$mem_load_limit = 0.8 # MEM usage limit 0.0-1.0 (%)
$mem_load_deviation = 0.1 # MEM usage deviation limit 0.0-1.0 (%)
$vm_slot_limit = 30   # VM count limit (#)

function Get-VMHostLoad {
    param(
        # VMHost List
        [Parameter(Mandatory = $true)]
        $VMHostList
    )
    foreach ($vmhost in $host_list) {
        $vmhost_obj = New-Object -TypeName PSObject
        $vmhost_obj | Add-Member -MemberType NoteProperty -Name name            -Value $VMHost.Name
        # $vmhost_obj | Add-Member -MemberType NoteProperty -Name cpuLoad -Value ($VMHost.CpuUsageMhz / $VMHost.CpuTotalMhz)
        $vmhost_obj | Add-Member -MemberType NoteProperty -Name MemoryUsagePerc -Value ($VMHost.MemoryUsageMB / $VMHost.MemoryTotalMB)
        $vmhost_obj | Add-Member -MemberType NoteProperty -Name MemoryUsageMB   -Value $VMHost.MemoryUsageMB
        $vmhost_obj | Add-Member -MemberType NoteProperty -Name MemoryTotalMB   -Value $VMHost.MemoryTotalMB
        # $vmhost_obj | Add-Member -MemberType NoteProperty -Name vmSlots -Value ($VMHost | Get-VM).Count
    }
    return $vmhost_obj
}

function Get-VMLoad {
    param(
        # VMHost Object
        [Parameter(Mandatory = $true)]
        $VM
    )
    foreach ($vm in $vm_list) {
        $vm_stats = $VM | Get-Stat -CPU -Memory -Realtime
        $vm_obj = New-Object -TypeName PSObject
        $vm_obj | Add-Member -MemberType NoteProperty -Name name          -Value $VM.Name
        $vm_obj | Add-Member -MemberType NoteProperty -Name MemoryUsageMB -Value ($vm_stats)
    }
    return $vmhost_obj
}

$cluster_list = Get-Cluster

foreach ($cluster in $cluster_list) {
    $host_list = $cluster | Get-VMHost
    $host_load_list = @()
    
    # Memory Balance
    $state = "WORKING"
    while ($state -eq "WORKING") {
        # Get current host list sorting by memory
        $host_load_list = Get-VMHostLoad $host_list | Sort MemoryUsagePerc
        # Save lowest host for reference
        $lowest_host = $host_load_list[$host_load_list.Count - 1]
        # Memory usage deviation between most loaded and least loaded
        $deviation = $host_load_list[0].MemoryUsagePerc - $lowest_host.MemoryUsagePerc
        # If deviation is greater than the predetermined ammount.
        if ($deviation -gt $mem_load_deviation) {
            $can_move = $false # Set initial value, assume cannot move
            # Get the list of VMs on most loaded host and sort by memory
            $vm_list = Get-VMHost -Name $host_load_list[0].Name | Get-VM | Where-Object {$_.PowerState -eq 'PoweredOn'} | Sort MemoryMB
            # Save lowest vm for reference
            $lowest_vm = $vm_load_list[$vm_load_list.Count - 1]
            
            # Calculate destination's new load after moving VM
            $dest_load = ($lowest_host.MemoryUsageMB + $lowest_vm.MemoryUsageMB) / $lowest_host.MemoryTotalMB
            # Calculate source's new load after moving VM
            $source_load = ($host_load_list[0].MemoryUsageMB - $lowest_vm.MemoryUsageMB) / $host_load_list[0].MemoryTotalMB
            # New deviation
            $new_deviation = $source_load - $dest_load
            # Check new deviation < mem_load_limit and > mem_load_deviation
            if ($dest_load -lt $mem_load_limit -and $new_deviation -gt $mem_load_deviation ) {
                $can_move = $true
            }
            else {
                $state = "BREAK"
            }
            if ($can_move) {
                # Migrate lowest vm to lowest host
            }
        }
        else {
            $state = "BREAK"
        }
    }
}