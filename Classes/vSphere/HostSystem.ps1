class hostCPUInfo {
    #Defines the CPU hardware type and details for ESX server

    #Properties
    [string]$Model
    [string]$Sockets
    [string]$Cores
    [string]$speedTotalGHz
    [string]$speedPerCPUGHz
    [string]$hyperThreading_active
    [string]$hyperThreading_available
}

class hostHardwareInfo {
    #Defines the hardware info type and details for ESX server

    #Properties
    [string]$BIOS
    [string]$Vendor
    [string]$Model
    [hostCPUInfo]$cpuInfo
    [string]$MemoryGB   
}

class HostServiceInfo {
    #Define the available service info for ESXi host #

    #Properties
    [string]$ESXi_Shell_Running
    [string]$NTP_Running
    [string]$SNMP_Running
    [string]$SSH_Running
}

class HostSystem : vSphere {
    #vROps ESXi host type resource #

    #Properties
    [string]$Name
    [string]$Cluster
    [string]$Version
    [string]$Build
    [hostHardwareInfo]$HardwareInfo
    [string]$connectionState
    [string]$maintenanceState
    [string]$powerState
    [string]$IPAddress
    [HostServiceInfo]$ServiceInfo
    [string[]]$DNSServer
    [string[]]$VM
    [string[]]$Datastore
    [string]$vDS
    [string]$Environment
    [string]$Infrastructure
    [string[]]$Location
}