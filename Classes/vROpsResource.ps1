class vROpsResource {
    #Base class for all vROps resource #
    [string]$Name
    [string]$vROpsID
    [string]$Health
    [string]$Status
    [string]$vROpsServer
    [string]$ResourceType
    [string]$ResourceAdapterType

    <#vROpsResource($name,$id,$health,$status) {
        # Initialize the class. Use $this to reference the properties of the instance you are creating 
        $this.Name = $name
        $this.vROpsID = $id
        $this.Health = $health
        $this.Status = $status
    }
    #>
}