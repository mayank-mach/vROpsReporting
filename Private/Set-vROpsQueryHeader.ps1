function Set-vROpsQueryHeader
{
    [CmdletBinding()]
    param (
        # Specifies a path to one or more locations.
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Authentiation token for vROps REST API session.")]
        [ValidateNotNullOrEmpty()]
        [Alias("SessionSecret")]
        [string]$Token
    )
    
    begin
    {
              
    }
    
    process
    {
        #Creating header for vROPs authentication
        $header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $header.Add("Accept", 'application/json')
        $header.Add("Content-Type", 'application/json')
        $header.Add("Authorization", "vRealizeOpsToken $Token")

        Write-Output $header
    }
    
    end
    {
        
    }
}