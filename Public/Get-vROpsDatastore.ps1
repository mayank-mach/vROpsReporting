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
function Get-vROpsDatastore
{
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        # Specifies a path to one or more locations.
        [Parameter(ParameterSetName = "vCenter")]
        [Parameter(ParameterSetName = "Datacenter")]
        [Parameter(ParameterSetName = "Type")]
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
        [Parameter(ParameterSetName = "Type")]
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
                   ParameterSetName = "Type",
                   HelpMessage="Type of the vROps datastore resource.")]
        [ValidateSet("NFS", "vVol", "VMFS")]
        [string]
        $Type
    )
    
    begin
    {
        #Get all properties to search from
        $propertyKeys = Get-Content -Path "$PSScriptRoot\..\Config\properties\Datastore.json" -Raw | ConvertFrom-Json
    }
    
    process
    {
        #=============================================================================#
        #Get vROps resource ID

        #Create body for vROps Rest query
        $body = [PSCustomObject]@{
            adapterKind  = @( "VMWARE")
            resourceKind = @("Datastore")
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
        elseif ($PSCmdlet.ParameterSetName -eq 'Type')
        {
            $body | Add-Member -MemberType NoteProperty -Name 'propertyName' -Value 'summary|type'
            $body | Add-Member -MemberType NoteProperty -Name 'propertyValue' -Value $Type
        }

        if ($Name)
        {
            $body | Add-Member -MemberType NoteProperty -Name name -Value ''
            
            $resourceList = foreach ($item in $Name) {
                $body.name = @("$item")

                #Call internal function to vROps datstore resource info
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

        $DatastoreResources = foreach ($vROpsConnection in $vROpsGroups)
        {
            #Get resource IDs
            $resourceId = $vROpsConnection.Group | Select-Object -ExpandProperty vROpsID
            
            Write-Verbose "Generating object for resource ID $resourceId"
            #Get all properties for Cluster compute resources in the vROps server
            $properties = Get-vROpsResourceProperty -ID $resourceId -vROpsServer $vROpsConnection.Name -propertyKeys $propertyKeys

            #Get all relations for Cluster compute resources in the vROps server
            $relations = Get-vROpsResourceRelationship -ID $resourceId -vROpsServer $vROpsConnection.Name -bulkQuery

            foreach ($item in $vROpsConnection.Group)
            {
                $props = ($properties.values | Where-Object { $_.resourceId -eq $($item.vROpsID) }).'property-contents'.'property-content'
                $rels  = ($relations.resourcesRelations | Where-Object { $_.relatedResources -contains $($item.vROpsID) }).resource

                #Get datastore type
                $datastoreType = Get-resourceProperty -InputObject $props -Key 'summary|type' -Type Property
                switch ($datastoreType) {
                    'NFS' { 
                        $datastoreResource = [nfsDatastore]@{} 
                    }
                    'vVol' { 
                        $datastoreResource = [vvolDatastore]@{} 
                    }
                    'VMFS' { 
                        $datastoreResource = [vmfsDatastore]@{} 
                    }
                }

                $datastoreResource.Name              = Get-resourceProperty -InputObject $props -Key 'config|name' -Type Property
                $datastoreResource.vCenter           = Get-resourceProperty -InputObject $props -Key 'summary|parentVcenter' -Type Property
                $datastoreResource.Datacenter        = Get-resourceProperty -InputObject $props -Key 'summary|parentDatacenter' -Type Property
                $datastoreResource.Type              = Get-resourceProperty -InputObject $props -Key 'summary|type' -Type Property
                $datastoreResource.isLocal           = Get-resourceProperty -InputObject $props -Key 'summary|isLocal' -Type Property
                $datastoreResource.Folder            = Get-resourceProperty -InputObject $props -Key 'summary|folder' -Type Property
                $datastoreResource.CapacityGB        = Get-resourceProperty -InputObject $props -Key 'summary|diskCapacity' -Type Property
                $datastoreResource.Accessible        = Get-resourceProperty -InputObject $props -Key 'summary|accessible' -Type Property
                $datastoreResource.Cluster           = Get-resourceProperty -InputObject $rels -Key 'ClusterComputeResource' -Type Relation
                $datastoreResource.vmHost            = Get-resourceProperty -InputObject $rels -Key 'HostSystem' -Type Relation
                $datastoreResource.VM                = Get-resourceProperty -InputObject $rels -Key 'VirtualMachine' -Type Relation
                $datastoreResource.SDRS_Cluster      = Get-resourceProperty -InputObject $rels -Key 'StoragePod' -Type Relation
                $datastoreResource.Environment       = Get-resourceProperty -InputObject $rels -Key 'Environment' -Type Relation
                $datastoreResource.Infrastructure    = Get-resourceProperty -InputObject $rels -Key 'Infrastructure' -Type Relation
                $datastoreResource.Location          = Get-resourceProperty -InputObject $rels -Key 'Location' -Type Relation
                $datastoreResource.vROpsResourceInfo = $item

                if($type -eq 'VVOL')
                {
                    $datastoreResource.ArrayInfo = [storageArrayInfo]@{
                        Model  = Get-resourceProperty -InputObject $props -Key 'storageArray|modelId' -Type Property
                        Name   = Get-resourceProperty -InputObject $props -Key 'storageArray|name' -Type Property
                        ID     = Get-resourceProperty -InputObject $props -Key 'storageArray|id' -Type Property
                        vendor = Get-resourceProperty -InputObject $props -Key 'storageArray|vendorId' -Type Property
                    }
                }
                
                Write-Output $datastoreResource
            }
        }
    }
    
    end
    {
        Write-Output $DatastoreResources
    }
}