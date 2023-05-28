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
function Get-vROpsVM
{
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        # Specifies a path to one or more locations.
        [Parameter(ParameterSetName = "vCenter")]
        [Parameter(ParameterSetName = "Datacenter")]
        [Parameter(ParameterSetName = "Cluster")]
        [Parameter(ParameterSetName = "VMHost")]
        [Parameter(ParameterSetName = "Datastore")]
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
        [Parameter(ParameterSetName = "VMHost")]
        [Parameter(ParameterSetName = "Datastore")]
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
            HelpMessage = "Datacenter for the vROps resource.")]
        [string]
        $Datacenter,

        # Specifies a path to one or more locations.
        [Parameter(
            ParameterSetName = "Cluster",
            HelpMessage = "Cluster for the vROps resource.")]
        [string]
        $Cluster,

        # Specifies a path to one or more locations.
        [Parameter(
            ParameterSetName = "VMHost",
            HelpMessage = "VMHost for the vROps resource.")]
        [string]
        $VMHost,

        # Specifies a path to one or more locations.
        [Parameter(
            ParameterSetName = "Datastore",
            HelpMessage = "Datastore where vm config files are present.")]
        [string]
        $Datastore
    )
    
    begin
    {
        #Get all properties to search from
        $propertyKeys = Get-Content -Path "$PSScriptRoot\..\Config\properties\VirtualMachine.json" -Raw | ConvertFrom-Json
    }
    
    process
    {
        #=============================================================================#
        #Get vROps resource ID

        #Create body for vROps Rest query
        $body = [PSCustomObject]@{
            adapterKind  = @( "VMWARE")
            resourceKind = @("VirtualMachine")
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
        elseif ($PSCmdlet.ParameterSetName -eq 'VMHost')
        {
            $body | Add-Member -MemberType NoteProperty -Name 'propertyName' -Value 'summary|parentHost'
            $body | Add-Member -MemberType NoteProperty -Name 'propertyValue' -Value $VMHost
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Datastore')
        {
            $body | Add-Member -MemberType NoteProperty -Name 'propertyName' -Value 'summary|datastore'
            $body | Add-Member -MemberType NoteProperty -Name 'propertyValue' -Value $Datastore
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
            $relations = Get-vROpsResourceRelationship -ID $resourceId -vROpsServer $vROpsConnection.Name

            foreach ($item in $vROpsConnection.Group)
            {
                $props = ($properties | Where-Object { $_.resourceId -eq $($item.vROpsID) }).'property-contents'.'property-content'
                $rels  = ($relations | Where-Object { $_.relatedResources -contains $($item.vROpsID) }).resource

                $vmHostresource = [VirtualMachine]@{
                    Name              = Get-resourceProperty -InputObject $props -Key 'config|name' -Type Property
                    vCenter           = Get-resourceProperty -InputObject $props -Key 'summary|parentVcenter' -Type Property
                    Datacenter        = Get-resourceProperty -InputObject $props -Key 'summary|parentDatacenter' -Type Property
                    Cluster           = Get-resourceProperty -InputObject $props -Key 'summary|parentCluster' -Type Property
                    VMHost            = Get-resourceProperty -InputObject $props -Key 'summary|parentHost' -Type Property
                    VMVersion         = Get-resourceProperty -InputObject $props -Key 'config|version' -Type Property
                    Folder            = Get-resourceProperty -InputObject $props -Key 'summary|parentFolder' -Type Property
                    OSVersionInfo     = Get-resourceProperty -InputObject $props -Key 'summary|guest|fullName' -Type Property
                    HardwareInfo = [VirtualMachineHardwareInfo]@{
                        cpuInfo  = [VirtualMachineCPUInfo]@{
                            Cores          = Get-resourceProperty -InputObject $props -Key 'config|hardware|numCpu' -Type Property
                            CoresPerSocket = Get-resourceProperty -InputObject $props -Key 'config|hardware|numCoresPerSocket' -Type Property
                            NumSockets     = Get-resourceProperty -InputObject $props -Key 'config|hardware|numSockets' -Type Property
                            speedGHz       = Get-resourceProperty -InputObject $props -Key 'cpu|speed' -Type Property
                        }
                        MemoryGB = Get-resourceProperty -InputObject $props -Key 'config|hardware|memoryKB' -Type Property
                    }
                    vmToolsInfo = [VirtualMachineVMToolsInfo]@{
                        toolsRunningStatus  = Get-resourceProperty -InputObject $props -Key 'summary|guest|toolsRunningStatus' -Type Property
                        toolsVersion        = Get-resourceProperty -InputObject $props -Key 'summary|guest|toolsVersion' -Type Property
                        toolsVersionStatus2 = Get-resourceProperty -InputObject $props -Key 'summary|guest|toolsVersionStatus2' -Type Property
                    }
                    NumHardDisk       = Get-resourceProperty -InputObject $props -Key 'config|numVMDKs' -Type Property
                    NumNetAdapter     = Get-resourceProperty -InputObject $props -Key 'summary|config|numEthernetCards' -Type Property
                    VMGuestName       = Get-resourceProperty -InputObject $props -Key 'summary|guest|hostName' -Type Property
                    connectionState   = Get-resourceProperty -InputObject $props -Key 'summary|runtime|connectionState' -Type Property
                    powerState        = Get-resourceProperty -InputObject $props -Key 'summary|runtime|powerState' -Type Property
                    IPAddress         = Get-resourceProperty -InputObject $props -Key 'summary|guest|ipAddress' -Type Property
                    Datastore         = Get-resourceProperty -InputObject $props -Key 'summary|datastore' -Type Property
                    vDPortGroup       = Get-resourceProperty -InputObject $rels -Key 'DistributedVirtualPortgroup' -Type Relation
                    vDS               = Get-resourceProperty -InputObject $rels -Key 'VmwareDistributedVirtualSwitch' -Type Relation
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