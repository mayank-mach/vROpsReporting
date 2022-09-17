function Get-allvROpsConnections
{
    process
    {
        if ( !$Global:vROPsServersConnectionInfo )
        {
            Write-Warning "You are not connected to any vROps Server. To create a new connection use Connect-vROpsServer."
        }
        else
        {
            $allActiveConnections = $Global:vROPsServersConnectionInfo|Where-Object{$_.validity -gt (Get-Date)}

            Write-Output $allActiveConnections
        }
    }
}