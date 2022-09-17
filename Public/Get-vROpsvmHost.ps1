<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>
function Get-vROpsvmHost
{
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        # Specifies a path to one or more locations.
        [Parameter(ParameterSetName = "vCenter")]
        [Parameter(ParameterSetName = "Datacenter")]
        [Parameter(ParameterSetName = "Cluster")]
        [Parameter(
            ParameterSetName = "Default",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Name of 1 or more HostSystem to search in vROps.")]
        [string[]]
        $Name,

        # Specifies a path to one or more locations.
        [Parameter(ParameterSetName = "vCenter")]
        [Parameter(ParameterSetName = "Datacenter")]
        [Parameter(ParameterSetName = "Cluster")]
        [Parameter(
            ParameterSetName = "Default",
            HelpMessage = "vROps server where to search for object.")]
        [string]
        $vROpsServer,

        # Specifies a path to one or more locations.
        [Parameter(
            ParameterSetName = "vCenter",
            HelpMessage = "vCenter for the vROps resource.")]
        [string]
        $vCenter,

        # Specifies a path to one or more locations.
        [Parameter(
            ParameterSetName = "Datacenter",
            HelpMessage = "vCenter for the vROps resource.")]
        [string]
        $Datacenter,

        # Specifies a path to one or more locations.
        [Parameter(
            ParameterSetName = "Cluster",
            HelpMessage = "vCenter for the vROps resource.")]
        [string]
        $Cluster
    )
    
    begin
    {
        #Get all properties to search from
        $propertyKeys = Get-Content -Path "$PSScriptRoot\..\Config\properties\HostSystem.json" -Raw | ConvertFrom-Json
    }
    
    process
    {
        #=============================================================================#
        #Get vROps resource ID

        #Create body for vROps Rest query
        $body = [PSCustomObject]@{
            adapterKind  = @( "VMWARE")
            resourceKind = @("HostSystem")
        }       

        if ($PSCmdlet.ParameterSetName -eq 'vCenter')
        {
            $body | Add-Member -MemberType NoteProperty -Name 'propertyName' -Value 'summary|parentVcenter'
            $body | Add-Member -MemberType NoteProperty -Name 'propertyValue' -Value $vCenter
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Datacenter')
        {
            $body | Add-Member -MemberType NoteProperty -Name 'propertyName' -Value 'summary|parentDatacenter'
            $body | Add-Member -MemberType NoteProperty -Name 'propertyValue' -Value $Datacenter
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Cluster')
        {
            $body | Add-Member -MemberType NoteProperty -Name 'propertyName' -Value 'summary|parentCluster'
            $body | Add-Member -MemberType NoteProperty -Name 'propertyValue' -Value $Cluster
        }

        if ($Name)
        {
            $body | Add-Member -MemberType NoteProperty -Name name -Value ''
            
            $resourceList = foreach ($item in $Name) {
                $body.name = @("$item")

                #Call internal function to vROps cluster resource info
                Write-Verbose "Searching for $item in vROps environment"
                if ($vROpsServer)
                {
                    Get-vROpsResource -RequestContent $body -vROpsServer $vROpsServer
                }
                else
                {
                    Get-vROpsResource -RequestContent $body
                }
            }
        }
        else
        {
            #Call internal function to vROps cluster resource info
            if ($vROpsServer)
            {
                $resourceList = Get-vROpsResource -RequestContent $body -vROpsServer $vROpsServer
            }
            else
            {
                $resourceList = Get-vROpsResource -RequestContent $body
            }
        }

        #=============================================================================#
        #Get resource properties
        $vROpsGroups = $resourceList | Group-Object -Property vROpsServer

        $vmHostresources = foreach ($vROpsConnection in $vROpsGroups)
        {
            #Get resource IDs
            $resourceId = $vROpsConnection.Group | Select-Object -ExpandProperty vROpsID
            
            #Get all properties for Cluster compute resources in the vROps server
            $properties = Get-vROpsResourceProperty -ID $resourceId -vROpsServer $vROpsConnection.Name -propertyKeys $propertyKeys

            #Get all relations for Cluster compute resources in the vROps server
            $relations = Get-vROpsResourceRelationship -ID $resourceId -vROpsServer $vROpsConnection.Name -bulkQuery

            foreach ($item in $vROpsConnection.Group)
            {
                $props = ($properties.values | Where-Object { $_.resourceId -eq $($item.vROpsID) }).'property-contents'.'property-content'
                $rels  = ($relations.resourcesRelations | Where-Object { $_.relatedResources -contains $($item.vROpsID) }).resource

                $vmHostresource = [HostSystem]@{
                    Name              = Get-resourceProperty -InputObject $props -Key 'config|name' -Type Property
                    vCenter           = Get-resourceProperty -InputObject $props -Key 'summary|parentVcenter' -Type Property
                    Datacenter        = Get-resourceProperty -InputObject $props -Key 'summary|parentDatacenter' -Type Property
                    Cluster           = Get-resourceProperty -InputObject $props -Key 'summary|parentCluster' -Type Property
                    Version           = Get-resourceProperty -InputObject $props -Key 'summary|version' -Type Property
                    Build             = Get-resourceProperty -InputObject $props -Key 'sys|build' -Type Property
                    HardwareInfo = [hostHardwareInfo]@{
                        BIOS     = Get-resourceProperty -InputObject $props -Key 'hardware|biosVersion' -Type Property
                        Vendor   = Get-resourceProperty -InputObject $props -Key 'hardware|vendor' -Type Property
                        Model    = Get-resourceProperty -InputObject $props -Key 'hardware|vendorModel' -Type Property
                        cpuInfo  = [hostCPUInfo]@{
                            Model                    = Get-resourceProperty -InputObject $props -Key 'cpu|cpuModel' -Type Property
                            Sockets                  = Get-resourceProperty -InputObject $props -Key 'hardware|cpuInfo|numCpuPackages' -Type Property
                            Cores                    = Get-resourceProperty -InputObject $props -Key 'hardware|cpuInfo|numCpuCores' -Type Property
                            speedTotalGHz            = Get-resourceProperty -InputObject $props -Key 'cpu|speed' -Type Property
                            speedPerCPUGHz           = Get-resourceProperty -InputObject $props -Key 'hardware|cpuInfo|hz' -Type Property
                            hyperThreading_active    = Get-resourceProperty -InputObject $props -Key 'config|hyperThread|active' -Type Property
                            hyperThreading_available = Get-resourceProperty -InputObject $props -Key 'config|hyperThread|available' -Type Property
                        }
                        MemoryGB = Get-resourceProperty -InputObject $props -Key 'hardware|memorySize' -Type Property
                    }
                    connectionState   = Get-resourceProperty -InputObject $props -Key 'runtime|connectionState' -Type Property
                    maintenanceState  = Get-resourceProperty -InputObject $props -Key 'runtime|maintenanceState' -Type Property
                    powerState        = Get-resourceProperty -InputObject $props -Key 'runtime|powerState' -Type Property
                    IPAddress         = Get-resourceProperty -InputObject $props -Key 'net|mgmt_address' -Type Property
                    DNSServer         = Get-resourceProperty -InputObject $props -Key 'config|network|dnsserver' -Type Property
                    ServiceInfo = [HostServiceInfo]@{
                        ESXi_Shell_Running = Get-resourceProperty -InputObject $props -Key 'config|security|service:ESXi Shell|isRunning' -Type Property
                        NTP_Running        = Get-resourceProperty -InputObject $props -Key 'config|security|service:NTP Daemon|isRunning' -Type Property
                        SNMP_Running       = Get-resourceProperty -InputObject $props -Key 'config|security|service:SNMP Server|isRunning' -Type Property
                        SSH_Running        = Get-resourceProperty -InputObject $props -Key 'config|security|service:SSH|isRunning' -Type Property
                    }
                    vDS               = Get-resourceProperty -InputObject $rels -Key 'VmwareDistributedVirtualSwitch' -Type Relation
                    VM                = Get-resourceProperty -InputObject $rels -Key 'VirtualMachine' -Type Relation
                    Datastore         = Get-resourceProperty -InputObject $rels -Key 'Datastore' -Type Relation
                    Environment       = Get-resourceProperty -InputObject $rels -Key 'Environment' -Type Relation
                    Infrastructure    = Get-resourceProperty -InputObject $rels -Key 'Infrastructure' -Type Relation
                    Location          = Get-resourceProperty -InputObject $rels -Key 'Location' -Type Relation
                    vROpsResourceInfo = $item
                }
                Write-Output $vmHostresource
            }
        }
    }
    
    end
    {
        Write-Output $vmHostresources
    }
}