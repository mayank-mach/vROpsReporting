function Get-vROpsResourceRelationship
{
    [CmdletBinding()]
    param (
        # One of more ID of vROps Object for which relations are required.
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ID,

        # vROps Server to query object relations.
        [Parameter(Mandatory = $true,
            Position = 1,
            HelpMessage = "Path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        [string]
        $vROpsServer,

        # Switch parameter to query for multiple resources
        [Parameter(HelpMessage="Path to one or more locations.")]
        [switch]
        $bulkQuery
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

        if( $bulkQuery.IsPresent )
        {
            $url = "https://$vROpsServer/suite-api/api/resources/bulk/relationships?pageSize=100000"
            
            if ($ID.Count -eq 1)
            {   
                $body = [PSCustomObject]@{
                    relationshipType = 'ALL'
                    resourceIds      = @("$ID")
                    hierarchyDepth   = 10
                } | ConvertTo-Json
            }
            else 
            {
                $body = [PSCustomObject]@{
                    relationshipType = 'ALL'
                    resourceIds      = $ID
                    hierarchyDepth   = 10
                } | ConvertTo-Json
            }           
        }
        else
        {
            $url = "https://$vROpsServer/suite-api/api/resources/$ID/relationships"                               
        }
        try
        {
            if($body)
            {
                $relations = Invoke-RestMethod -Method Post -Uri $url -Headers $header -Body $body
            }
            else
            {
                $relations = Invoke-RestMethod -Method Get -Uri $url -Headers $header 
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
        if ($relations)
        {
            Write-Output $relations
        }        
    }
}