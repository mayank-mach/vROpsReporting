class Datastore : vSphere {
    #vROps NFS datastore type resource #

    #Properties
    [string]$Name
    [string[]]$Cluster
    [string[]]$vmHost
    [string[]]$VM
    [string]$Type
    [string]$isLocal
    [string]$Folder
    [string]$CapacityGB
    [string]$Accessible
    [string]$SDRS_Cluster
    [string]$Environment
    [string]$Infrastructure
    [string[]]$Location
}

class storageArrayInfo {
    #Define storage array info for vvol datastore #

    #Properties
    [string]$ID
    [string]$Model
    [string]$Name
    [string]$vendor
}
class vvolDatastore : Datastore{
    #vROps VVOL datstore hardware type resource #

    #Properties
    [storageArrayInfo]$ArrayInfo
}

class nfsDatastore : Datastore {
    #vROps VVOL datstore type resource #

}

class vmfsDatastore : Datastore {
    #vROps ESXi host type resource #

}