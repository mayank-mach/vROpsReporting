function Get-vROpsResource
{
    [CmdletBinding()]
    param (
        # Specifies a path to one or more locations.
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $RequestContent,

        # Specifies a path to one or more locations.
        [Parameter(HelpMessage = "Path to one or more locations.")]
        [string]
        $vROpsServer
    )
    
    begin
    {
        if ($vROpsServer)
        {
            $allActiveConnections = Get-allvROpsConnections | Where-Object { $_.vROPsServer -eq $vROpsServer }
        }
        else
        {
            $allActiveConnections = Get-allvROpsConnections
        }

        #1st page number default for all queries
        $page = 0
    }
    
    process
    {
        if ( !$allActiveConnections )
        {
            Write-Warning "You are not connected to any vROps Server. To create a new connection use Connect-vROpsServer."
        }
        
        foreach ($vROpsConnection in $allActiveConnections)
        {
            $body = $RequestContent|ConvertTo-Json
            Write-Verbose -Message "Using below mentioned query to get resources matching the criteria."
            Write-Verbose -Message $body
            $header = $vROpsConnection | Set-vROpsQueryHeader #Using private function to create header for the REST query.
                
            try 
            {
                #do-while loop will get resource data for all resources in case of multi page query too
                $resources = do 
                {
                    #URL to create REST API query
                    $url = "https://$($vROpsConnection.vROPsServer)/suite-api/api/resources/query?page=$page&amp;pageSize=1000"
                    $queryOutput = Invoke-RestMethod -Method Post -Uri $url -Headers $header -Body $body -ErrorAction Stop
                    
                    $page += 1 # update page counter
                    Write-output $queryOutput.resourceList #send result to variable outside the loop
                } while ( $queryOutput.links.name -eq 'next' )
            }
            catch [System.Net.WebException]
            {
                if ($_.Exception.Status -eq 'ProtocolError')
                {
                    Write-Warning "Response from $($vROpsConnection.vROPsServer) : $($_.Exception.Response.StatusCode)"
                }
                elseif ($_.Exception.Status -eq 'NameResolutionFailure') 
                {
                    Write-Warning "$_"
                }
                else 
                {
                    Write-Warning "$_"
                }
            }
            catch 
            {
                if ($_ -like "No such host is known*") 
                {
                    $warn = "vROps server $($vROpsConnection.vROPsServer) is not reachable or invalid, please check the network connectivity and try again."
                    Write-Warning $warn
                }
                else
                {
                    Write-Warning "$_"
                }        
            }   

            if ($resources)
            {                
                Write-Verbose -Message "Found $($resources.count) resources matching the criteria, mentioned below are their vROpsIDs."
                Write-Verbose -Message $(($resources|select -ExpandProperty identifier) -join ',')
                foreach ($resource in $resources)
                {
                    $vROpsResource = [vROpsResource]::New()

                    $vROpsResource.Name                = $resource.resourceKey.name
                    $vROpsResource.vROpsID             = $resource.identifier
                    $vROpsResource.Health              = $resource.resourceHealth
                    $vROpsResource.Status              = $resource.resourceStatusStates.resourceStatus
                    $vROpsResource.vROpsServer         = $vROpsConnection.vROPsServer
                    $vROpsResource.ResourceType        = $resource.resourceKey.resourceKindKey
                    $vROpsResource.ResourceAdapterType = $resource.resourceKey.adapterKindKey

                    Write-Output $vROpsResource
                }

                <#break if searching for an object in vROps, if general query loop around all active connections or 
                for the requested server#>
                if ($RequestContent | Where-Object { $_.Name })
                {
                    break
                }
            }
            
        }
    }
    
    end
    {
        
    }
}