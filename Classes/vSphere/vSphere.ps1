class vSphere
{
    # Parent class for all vROps resource types obtained from vROps REST queries#
    [string]$vCenter
    [string]$Datacenter
    [vROpsResource]$vROpsResourceInfo

    [VMware.VimAutomation.ViCore.Impl.V1.VIServerImpl] ConnectVIserver([System.Management.Automation.PSCredential]$credential) 
    {
        <# Method will import VMware.VimAutomation.Core module and initiate vCenter connection using Connect-Viserver command #>
        try
        {
            $connectionInfo = Connect-VIServer $($this.vCenter) -Credential $Credential -ErrorAction Stop
            Write-Host  "Connected to the vCenter $($global:DefaultVIServer.Name)" -ForegroundColor Green
            return $connectionInfo
        }
        catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]
        {
            throw "Credentials provided for login to $($this.vCenter) are not valid"
        }   
        catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException]
        {
            throw "vCenter server $($this.vCenter) is not reachable, please check the network connectivity and try again."
        }
        Catch
        {
            throw "$($PSItem.Exception.Message)"
        }  
    }

    [void] ConnectvCenterGUI([System.Management.Automation.PSCredential]$credential) 
    {

    }
}