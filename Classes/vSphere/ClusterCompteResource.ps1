
class clusterDRSConfig {
    #Cluster DRS status

    [System.Boolean]$Enabled
    [System.Boolean]$admissionControl
}

class clusterHAConfig {
    #Cluster HA status

    [System.Boolean]$Enabled
    [System.Boolean]$defaultBehaviour
}

class clusterDPMConfig {
    #Cluster DPM status

    [System.Boolean]$Enabled
    [System.Boolean]$defaultBehaviour
}

class ClusterCompteResource : vSphere {
    #vROps Compute cluster type resource #

    #Properties
    [string]$Name
    [clusterHAConfig]$HA
    [clusterDRSConfig]$DRS
    [clusterDPMConfig]$DPM
    [string]$Environment
    [string]$Infrastructure
    [string[]]$vmHost
    [string[]]$VM
    [string[]]$Datastore
    [string[]]$Location
}