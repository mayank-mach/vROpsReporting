class VirtualMachineCPUInfo {
    #Defines the CPU hardware type and details for VirtualMachine

    #Properties
    [string]$Cores
    [string]$CoresPerSocket
    [string]$NumSockets
    [string]$speedGHz
}

class VirtualMachineHardwareInfo {
    #Defines the hardware info type and details for VirtualMachine

    #Properties
    [VirtualMachineCPUInfo]$cpuInfo
    [string]$MemoryGB   
}

class VirtualMachineVMToolsInfo {
    #Defines the vmTools info type and details for VirtualMachine

    #Properties
    [string]$toolsRunningStatus
    [string]$toolsVersion
    [string]$toolsVersionStatus2
}

class VirtualMachine : vSphere {
    #vROps ESXi host type resource #

    #Properties
    [string]$Name
    [string]$Cluster
    [string]$VMHost
    [string]$VMVersion
    [string]$Folder
    [string]$OSVersionInfo
    [string]$VMGuestName
    [VirtualMachineHardwareInfo]$HardwareInfo
    [VirtualMachineVMToolsInfo]$vmToolsInfo
    [string]$connectionState
    [string]$powerState
    [string]$IPAddress
    [string[]]$Datastore
    [string]$NumHardDisk
    [string]$NumNetAdapter
    [string[]]$vDPortGroup
    [string[]]$vDS
    [string]$Environment
    [string]$Infrastructure
    [string[]]$Location
}