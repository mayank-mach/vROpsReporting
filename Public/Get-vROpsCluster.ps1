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
function Get-vROpsCluster
{
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        # Specifies a path to one or more locations.
        [Parameter(ParameterSetName = "vCenter")]
        [Parameter(ParameterSetName = "Datacenter")]
        [Parameter(
            ParameterSetName = "Default",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Name of 1 or more clusterComputeResource to search in vROps.")]
        [string[]]
        $Name,

        # Specifies a path to one or more locations.
        [Parameter(ParameterSetName = "vCenter")]
        [Parameter(ParameterSetName = "Datacenter")]
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
        $Datacenter
    )
    
    begin
    {
        #Get all properties to search from
        $propertyKeys = Get-Content -Path "$PSScriptRoot\..\Config\properties\ClusterComputeResource.JSON" -Raw | ConvertFrom-Json
    }
    
    process
    {
        #=============================================================================#
        #Get vROps resource ID

        #Create body for vROps Rest query
        $body = [PSCustomObject]@{
            adapterKind  = @("VMWARE")
            resourceKind = @("ClusterComputeResource")
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

        if ($Name)
        {
            $body | Add-Member -MemberType NoteProperty -Name name -Value ''
            
            $resourceList = $Name | ForEach-Object {
                $body.name = @("$PSItem")

                #Call internal function to vROps cluster resource info
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

        $ClusterResources = foreach ($vROpsConnection in $vROpsGroups)
        {
            #Get resource IDs
            $resourceId = $vROpsConnection.Group | Select-Object -ExpandProperty vROpsID
            
            #Get all properties for Cluster compute resources in the vROps server
            $properties = Get-vROpsResourceProperty -ID $resourceId -vROpsServer $vROpsConnection.Name -propertyKeys $propertyKeys

            #Get all relations for Cluster compute resources in the vROps server
            $relations = Get-vROpsResourceRelationship -ID $resourceId -vROpsServer $vROpsConnection.Name

            foreach ($item in $vROpsConnection.Group)
            {
                Write-Verbose -Message "Getting details for vROps object $($item.name) with ID $($item.vROpsID)"
                $props = ($properties | Where-Object { $_.resourceId -eq $item.vROpsID }).'property-contents'.'property-content'
                $rels  = ($relations | Where-Object { $_.relatedResources -contains $item.vROpsID }).resource

                $clusterResource = [ClusterCompteResource]@{
                    Name              = Get-resourceProperty -InputObject $props -Key "config|name" -Type Property
                    vCenter           = Get-resourceProperty -InputObject $props -Key "summary|parentVcenter" -Type Property
                    Datacenter        = Get-resourceProperty -InputObject $props -Key "summary|parentDatacenter" -Type Property
                    HA = [clusterHAConfig]@{
                        Enabled          = Get-resourceProperty -InputObject $props -Key "configuration|dasConfig|enabled" -Type Property
                        defaultBehaviour = Get-resourceProperty -InputObject $props -Key "configuration|dasConfig|admissionControlEnabled" -Type Property
                    }
                    DRS = [clusterDRSConfig]@{
                        Enabled          = Get-resourceProperty -InputObject $props -Key "configuration|drsConfig|enabled" -Type Property
                        admissionControl = Get-resourceProperty -InputObject $props -Key "configuration|drsConfig|defaultVmBehavior" -Type Property
                    }
                    DPM = [clusterDPMConfig]@{
                        Enabled          =  Get-resourceProperty -InputObject $props -Key "configuration|dpmConfiginfo|enabled" -Type Property
                        defaultBehaviour =  Get-resourceProperty -InputObject $props -Key "configuration|dpmConfiginfo|defaultDpmBehavior" -Type Property
                    }
                    VM                = Get-resourceProperty -InputObject $rels -Key 'VirtualMachine' -Type Relation
                    vmHost            = Get-resourceProperty -InputObject $rels -Key 'HostSystem' -Type Relation
                    Datastore         = Get-resourceProperty -InputObject $rels -Key 'Datastore' -Type Relation
                    Environment       = Get-resourceProperty -InputObject $rels -Key 'Environment' -Type Relation
                    Infrastructure    = Get-resourceProperty -InputObject $rels -Key 'Infrastructure' -Type Relation
                    Location          = Get-resourceProperty -InputObject $rels -Key 'Location' -Type Relation
                    vROpsResourceInfo = $item
                }
                Write-Output $clusterResource
            }
        }
    }
    
    end
    {
        Write-Output $ClusterResources
    }
}