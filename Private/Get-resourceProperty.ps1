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
function Get-resourceProperty
{
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        # Specifies a path to one or more locations.
        [Parameter()]
        [System.Object[]]
        $InputObject,

        # Specifies a path to one or more locations.
        [Parameter(Mandatory=$true,
                Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Key,

        # Specifies a path to one or more locations.
        [Parameter(Mandatory=$true,
                Position=2)]
        [ValidateSet("Property","Relation","Stats")]
        [string]
        $Type
    )

    if( $InputObject )
    {
        if ($Type -eq 'Property') 
        {
            $propertyData = $InputObject | Where-Object { $_.statKey -eq $Key }

            if($propertyData.values)
            {
                $outputData = $propertyData.values
            }
            elseif ($propertyData.data) 
            {
                $outputData = $propertyData.data 
            }
        }
        elseif ($Type -eq 'Relation') 
        {
            $propertyData = $InputObject | Where-Object { $_.resourceKey.resourceKindKey -eq $Key } 

            if($propertyData)
            {
                $outputData = $propertyData.resourceKey.name
            }
        }  
    }

    #Send output
    if ( $outputData )
    {
        Write-Output $outputData
    }
    else
    {
        Write-Output $null
    }
}