function Get-vROpsResourceProperty
{
    [CmdletBinding()]
    param (
        # One of more ID of vROps Object for which properties are required.
        [Parameter(ParameterSetName = "ResourceID")]
        [Parameter(ParameterSetName = "BulkQuery")]
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ID,

        # Properties to query from vROps server.
        [Parameter(Mandatory = $true,
            ParameterSetName = "BulkQuery",
            HelpMessage = "Path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $propertyKeys,

        # vROps Server to query object properties.
        [Parameter(Mandatory = $true,
            HelpMessage = "Path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        [string]
        $vROpsServer
    )
    
    begin
    {
        $allActiveConnections = Get-allvROpsConnections | Where-Object { $_.vROPsServer -eq $vROpsServer } | Select-Object -First 1

        $header = $allActiveConnections | Set-vROpsQueryHeader #Using private function to create header for the REST query.
    }
    
    process
    {
        if ( !$allActiveConnections )
        {
            Write-Warning "You are not connected to any vROps Server $vROpsServer. To create a new connection use Connect-vROpsServer."
        }

        if ($PSCmdlet.ParameterSetName -eq 'ResourceID')
        {
            $url = "https://$vROpsServer/suite-api/api/resources/$($ID[0])/properties"

            Write-Verbose -Message "Since properties are not provided as input, getting all properties for vROpsID $($ID[0]) using below URL"
            Write-Verbose -Message $url

        }
        elseif ($PSCmdlet.ParameterSetName -eq 'BulkQuery')
        {
            if($ID.count -eq 1)
            {
                $body = [PSCustomObject]@{
                    resourceIds = @("$ID")   
                    propertyKeys = $propertyKeys                
                } | ConvertTo-Json
            }
            else 
            {
                $body = [PSCustomObject]@{
                    resourceIds = $ID  
                    propertyKeys = $propertyKeys                
                } | ConvertTo-Json
            }
            
            $url = "https://$vROpsServer/suite-api/api/resources/properties/latest/query?pageSize=100000"

            Write-Verbose -Message "Querying all provided properties for all inputed vROpsIDs in bulk using below URL"
            Write-Verbose -Message $url
        }

        try
        {
            if($body)
            {
                $properties = Invoke-RestMethod -Method Post -Uri $url -Headers $header -Body $body -ErrorAction Stop
            }
            else
            {
                $properties = Invoke-RestMethod -Method Get -Uri $url -Headers $header -ErrorAction Stop
            }
        }
        catch [System.Net.WebException]
        {
            if ($_.Exception.Status -eq 'ProtocolError')
            {
                Write-Warning "Response from $vROpsServer : $($_.Exception.Response.StatusCode)"
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
                Write-Warning "vROps server $vROpsServer is not reachable or invalid, please check the network connectivity and try again."
            }
            else
            {
                Write-Warning "$_"
            }        
        }        
    }
    
    end
    {
        if ($properties)
        {
            Write-Output $properties
        }        
    }
}