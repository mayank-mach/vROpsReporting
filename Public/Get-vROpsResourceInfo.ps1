function Get-vROpsResourceInfo
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        # Specifies a path to one or more locations.
        [Parameter(HelpMessage = "Path to one or more locations.")]
        [string]
        $vROpsServer
    )
    
    begin
    {

    }
    
    process
    {
        $body = [PSCustomObject]@{
            name = @($Name)
        } | ConvertTo-Json

        if ($vROpsServer)
        {
            Get-vROpsResource -RequestContent $body -vROpsServer $vROpsServer
        }
        else
        {
            Get-vROpsResource -RequestContent $body
        }
    }
    
    end
    {
        
    }
}