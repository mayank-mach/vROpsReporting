<#
.Synopsis
   This cmdlet establishes a connection to a vROps Server system.
.DESCRIPTION
   This cmdlet establishes a connection to a vCenter Server system. The cmdlet starts a new session or re-establishes a previous session with a vROps Server system using the specified parameters.

   You can have more than one connection to the same server. To disconnect from a server, you need to close all active connections to this server. This cmdlet supports working with multiple
   default servers. If you select this option, every time when you connect to a different server by using the Connect-vROPsServer cmdlet, the new server connection is stored in an array variable
   together with the previously connected servers. This variable is named $itemsConnectionInfo and its initial value is an empty Generic array. When you run a cmdlet and
   the target servers cannot be determined from the specified parameters, the cmdlet runs against all servers stored in the array variable. To remove a server from the $itemsConnectionInfo variable, you
   can either use the Disconnect-vROps cmdlet to close all active connections to the server, or modify the value of $itemsConnectionInfo manually.
.EXAMPLE
   Connect-vROPsServer -vROPsServer Server -Credential $myCredentialsObject

   Connects to a vROps server by using a credential object.
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
#>
function Connect-vROPsServer
{
   [CmdletBinding()]
   [Alias()]
   [OutputType([String])]
   Param
   (
      # Credential local/domain that will be used to connect to vROps server
      [Parameter(Mandatory = $true,
         Position = 1)]
      [ValidateNotNull()]
      [ValidateNotNullOrEmpty()]
      [System.Management.Automation.PSCredential]$Credential,

      #FQDN or IP of the vROps server to connect
      [Parameter(Mandatory = $true,
         Position = 0,
         ValueFromPipeline = $true,
         ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNull()]
      [ValidateNotNullOrEmpty()]
      [string[]]$vROpsServer
   )

   Begin
   { 
      #Create Global variable to store vROps connection details and set type to generic list
      if ( !$Global:vROPsServersConnectionInfo )
      {
         $Global:vROPsServersConnectionInfo = New-Object 'System.Collections.Generic.List[object]'
      }
      
      #Credential in JSON format to be passed as body for request
      if ($Credential.GetNetworkCredential().UserName.ToCharArray() -contains "@" -and !$Credential.GetNetworkCredential().Domain) 
      {
         $userName = $Credential.GetNetworkCredential().UserName.Split('@')[0]
         $domain = $Credential.GetNetworkCredential().UserName.Split('@')[1].Split('.')[0]
      }
      elseif ($Credential.GetNetworkCredential().UserName.ToCharArray() -notcontains "@" -and !$Credential.GetNetworkCredential().Domain) 
      {
         $userName = $Credential.GetNetworkCredential().UserName
         $domain = $null
      }
      else 
      {
         $userName = $Credential.GetNetworkCredential().UserName
         $domain = $Credential.GetNetworkCredential().Domain
      }

      if ($domain)
      {
         $AuthJSON = [ordered]@{
            username   = $userName
            authSource = $domain
            password   = $Credential.GetNetworkCredential().password
         } | ConvertTo-Json
      }
      else 
      {
         $AuthJSON = [ordered]@{
            username = $userName
            password = $Credential.GetNetworkCredential().password
         } | ConvertTo-Json
      }
      
      #Header to get output as JOSN from REST query
      $header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
      $header.Add("Accept", 'application/json')
      $header.Add("Content-Type", 'application/json')
   }
   Process
   {
      foreach ($item in $vROpsServer)
      {
         #URL for vROPs authentication
         $BaseAuthURL = "https://$item/suite-api/api/auth/token/acquire"

         #Check whether connection with vROps server already exists
         if ( $Global:vROPsServersConnectionInfo | Where-Object { $_.vROPsServer -eq $item -and $validity -gt (Get-Date) } )
         {
            Write-Host "Re-establishing REST connection with vROps server $item"
         }
         else 
         {
            Write-Host "Establishing REST connection with vROps server $item"   
         }

         try
         {
            $vROPSSessionResponse = Invoke-RestMethod -Method POST -Uri $BaseAuthURL -Body $AuthJSON -Headers $header -ErrorAction Stop
            Write-Verbose "vROPs session token acquired"

            #Get token validity in local time zone
            $EpochTime = $vROPSSessionResponse.validity / 1000
            $validity = ([System.DateTimeOffset]::FromUnixTimeSeconds($EpochTime)).LocalDateTime

            #Get date time for when vROPs token will expire
            Write-Verbose "Session expiry time as per vROPs server $item is: $validity"

            #Create vROPsSessionInfo object
            $sessionInfo = [PSCustomObject]@{
               vROPsServer   = $item
               UserName      = $userName
               Domain        = $domain
               SessionSecret = $vROPSSessionResponse.token
               Validity      = $validity
            }

            #Remove existing connection for same vROPs server, users and domain.
            $existingSession = $Global:vROPsServersConnectionInfo | Where-Object { $_.vROPsServer -eq $sessionInfo.vROPsServer -and $_.UserName -eq $sessionInfo.UserName -and 
               $_.Domain -eq $sessionInfo.Domain }

            if ($existingSession)
            {
               $null = $Global:vROPsServersConnectionInfo.Remove($existingSession)

               #Store vROPs SessionInfo object in global variable
               $Global:vROPsServersConnectionInfo.Add($sessionInfo)                  
            }
            else 
            {
               #Store vROPs SessionInfo object in global variable
               $Global:vROPsServersConnectionInfo.Add($sessionInfo)
            }           
         }
         catch [System.Net.WebException]
         {
            if ($_.Exception.Status -eq 'ProtocolError')
            {
               Write-Warning "Response from $item : $($_.Exception.Response.StatusCode)"
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
               Write-Warning "vROps server $item is not reachable or invalid, please check the network connectivity and try again."
            }
            else
            {
               Write-Warning "$_"
            }
            
         }
      }
   }
   End
   {
   }
}