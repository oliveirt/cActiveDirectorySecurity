# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
        # Common Messages
        ADPSDriveError                          = An error occurred connecting to AD: PSDrive for Server '{0}'.
        ADDefaultPSDriveError                   = An error occurred connecting to AD: PSDrive for the default domain.
        IdentityNotFound                        = An error occurred locating an object with the identity specified ('{0}'). Identities must be passed in either distinguishedName or objectGUID format, or as a reference object. 
        IdentityTypeInvalid                     = An error occurred validating the identity reference ('{0}'). Reference objects must include either a distinguishedName or objectGUID property.
        GetAclError                             = An error occurred running Get-Acl on object '{0}'.
        NetBIOSDomainError                      = An error occurred resolving NetBIOS Domain Name for the Domain.
        # Function Add-ADObjectAce
        IdentityReferenceInvalid                = An error occurred translating the Identity Reference ('{0}') to a Sid value. Processing cannot continue.
        ObjectTypeNameNotFound                  = An error occurred locating the ObjectTypeName with the name specified ('{0}').
        InheritedObjectTypeNameNotFound         = An error occurred locating the InheritedObjectTypeName with the name specified ('{0}').
        CreateNewAceError                       = An error occurred creating the new Ace on object '{0}'.
        AddAceError                             = An error occurred adding the new Ace to existing Acl on object '{0}'.
        SetAclError                             = An error occurred applying updated Acl on object '{0}'.
        # Function Remove-ADObjectAce
        AceNotFound                             = An error occurred locating an Ace that matched the specified filter on object '{0}'.
        MultipleAceValuesFound                  = An error occurred locating a single Ace that matched the specified filter on object '{0}'. Multiple Ace values were returned ('{1}').
        MatchingAceNotFound                     = An error occurred locating an Ace within the Acl which matched the specified filter on object '{0}'.
        RemoveAceError                          = An error occurred removing the Ace from existing Acl on object '{0}'.
        ClearAclError                           = An error occurred applying updated Acl on object '{0}'.
        # Function Get-ADObjectRightsGUID
        RootDSEError                            = An error occurred enumerating Root DSE for the Domain.
        # Function Resolve-ObjectSidToName
        GetADObjectSidError                     = An error occurred resolving the name for Sid value '{0}'.
        # Function Resolve-NameToObjectSid
        TranslateNameError                      = An error occurred translating the objectSid for identity reference '{0}'.
        GetADObjectNameError                    = An error occurred resolving the objectSid for identity reference '{0}'. An object with the sAMAccountName value '{1}' could not be found.
'@
}

<#
.Synopsis
    Gets the permissions from the specified Active Directory Object.
.DESCRIPTION
    Gets the permissions / access control list (ACL) from the specified Active Directory Object.

    The function can either write to the standard output stream, or copy the information to the clipboard in tab-delimited format that can be pasted directly into a Microsoft Excel for review.
.EXAMPLE
    Get-AdUser -Identity JBloggs | Get-ADObjectAcl

    Gets the permissions for the ADUser Object 'JBloggs' from the default Active Directory Domain.
.EXAMPLE
    Get-ADObjectAcl -Identity 29f0c9c7-aef4-4823-99a1-0f5f1df395d5

    Gets the permissions for the ADObject with GUID '29f0c9c7-aef4-4823-99a1-0f5f1df395d5' from the default Acive Directory Domain.
.EXAMPLE
    Get-ADObjectAcl -Identity "OU=Domain Controllers,DC=contoso,DC=com"

    Gets the permissions for the ADObject with distinguishedName 'OU=Domain Controllers,DC=contoso,DC=com' from the default Acive Directory Domain.
.EXAMPLE
    Get-ADUser -filter {surname -eq "Bloggs"} | Get-ADObjectAcl -Clip

    Gets the permissions for all the ADUser objects with the surname 'Bloggs' from the default Active Directory Domain and copies those permissions to the clipboard in tab delimited format which can be pasted directly into Microsoft Excel.
.EXAMPLE
   Get-AdUser -Identity JBloggs -Server dc1.contoso.com | Get-ADObjectAcl -Server dc1.contoso.com

   Gets the permissions for the ADUser Object 'JBloggs' from the server 'dc1.contoso.com'.
.EXAMPLE
    Get-ADOrganizationalUnit -filter {name -eq "Domain Controllers"} | Get-ADObjectAcl -IsInherited $false

    Gets all non-inherited permissions from the 'Domain Controllers' Organizational Unit fom the default Active Directory Domain.
.EXAMPLE
    Get-ADObjectAcl -Identity "OU=Domain Controllers,DC=contoso,DC=com" -IdentityReference "BUILTIN\Administrators"

    Gets all permissions from the 'Domain Controllers' Organizational Unit from the default Active Directory Domain which are granted to the identity reference 'BUILTIN\Administrators'.
.EXAMPLE
    Get-ADObjectAcl -Identity "OU=Domain Controllers,DC=contoso,DC=com" -ActiveDirectoryRights GenericAll

    Gets all permissions from the 'Domain Controllers' Organizational Unit from the default Active Directory Domain which are granted the Active Directory Right 'GenericAll'.
.EXAMPLE
    Get-ADObjectAcl -Identity "cn=Users,DC=contoso,DC=com" -ObjectTypeName user

    Gets all permissions from the 'Users' container from the default Active Directory Domain which are granted over objects of type 'user'.
.EXAMPLE
    Get-ADObjectAcl -Identity "cn=Users,DC=contoso,DC=com" -ObjectTypeName RAS-Information -InheritedObjectTypeName user 

    Gets all permissions from the 'Users' container from the default Active Directory Domain which are granted over object type of 'RAS-Information' and inherited object of type of 'user'. 
.INPUTS
   The identity parameter of the CmdLet accepts either a distinguishedName or ObjectGUID or AD Objects. AD Objects which are passed by reference must include either a distinguishedName or ObjectGUID property.
.OUTPUTS
   Outputs the Access Control List from the Active Directory Object or Objects.
#>
function Get-ADObjectAcl
{
    [CmdletBinding(SupportsShouldProcess = $false, PositionalBinding = $true)]
    [OutputType([Object])]
    Param(
        # The Identity of the Active Directory Object in either distinguishedName or GUID format or by reference.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false, Position = 1)]
        [object]
        $Identity,
        
        # The target Active Directory Server / Domain Controller.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [string]
        $Server,

        # Send the output to the Clipboard in tab-delimited format (can be pasted directly into Microsoft Excel for review).
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Alias("Clip")]
        [switch]
        $SendToClipboard,

        # Filter the returned Access Control Entries based on IsInherited ($true / $false).
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [bool]
        $IsInherited,

        # Filter the returned Access Control Entries based on the IdentityReference of the ACE (DOMAIN\USERNAME).
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [string]
        $IdentityReference,

        # Filter the returned Access Control Entries based on the IdentityReference Name of the ACE (USERNAME).
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [string]
        $IdentityReferenceName,

        # Filter the returned Access Control Entries based on the IdentityReference Domain of the ACE (DOMAIN / BUILTIN / NT AUTHORITY).
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [string]
        $IdentityReferenceDomain,

        # Filter the returned Access Control Entries based on the Active Directory Rights of the ACE.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [ValidateSet( "CreateChild", "DeleteChild", "ListChildren", "Self", "ReadProperty", "WriteProperty", "DeleteTree", "ListObject", "ExtendedRight", "Delete", "ReadControl", "GenericExecute", "GenericWrite", "GenericRead", "WriteDacl", "WriteOwner", "GenericAll", "Synchronize", "AccessSystemSecurity")]
        [string[]]
        $ActiveDirectoryRights,

        # Filter the returned Access Control Entries based on the Object Type Name of the ACE.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [string]
        $ObjectTypeName,

        # Filter the returned Access Control Entries based on the Inherited Object Type Name of the ACE.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [string]
        $InheritedObjectTypeName,

        # Filter the returned Access Control Entries based on the Inheritance Type of the ACE.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [ValidateSet( "All", "DeleteChild", "Children", "Descendents", "ReadProperty", "None", "SelfAndChildren")]
        [string[]]
        $InheritanceType,

        # Filter the returned Access Control Entries based on the Access Control Type of the ACE (Allow / Deny)
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [ValidateSet("Allow", "Deny")]
        [string]
        $AccessControlType,

        # Credential to use.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ParameterSetName = "Credential")]
        [System.Management.Automation.PSCredential]
        $Credential
    )
    Begin
    {
        # no need to perform AD PSDrive setup if the command is being called by another function within the same module
        if ( ((Get-PSCallStack)[0].Location).Split(":")[0] -ne ((Get-PSCallStack)[1].Location).Split(":")[0])
        {
            Push-Location -StackName 'cActiveDirectorySecurity' # keep a record of the current location

            $PSDriveParams = @{"ErrorAction" = "Stop"}
        
            if ($PSBoundParameters.ContainsKey('Credential'))
            {
                $PSDriveParams.Add("Credential", $Credential)
            }
            if ($PSBoundParameters.ContainsKey('Server'))
            {
                $PSDriveParams.Add("Server", $Server)
            }
            else 
            {
                $Server = (Get-AdDomain).NetBIOSName
            }

            if (($PSBoundParameters.ContainsKey('Server')) -or ($PSBoundParameters.ContainsKey('Credential')))
            {
                try
                {
                    # create a new PSDrive to the target AD Domain Controller / or using different credentials
                    $PSDriveName = $Server.Split(".")[0]
                    New-PSDrive -Name $PSDriveName -PSProvider ActiveDirectory -root "//RootDSE/" @PSDriveParams | Out-Null
                    Set-Location ($PSDriveName + ":") -ErrorAction Stop
                    Write-Verbose "Connecting to specified server / domain controller."
                    Write-Verbose -Message "Server: $Server"
                }
                catch
                {
                    Write-Warning -Message ($LocalizedData.ADPSDriveError -f $Server)
                    Pop-Location
                    throw $_
                }
            }
            else
            {
                # connect to the default Active Directory PSDrive
                try
                {
                    Set-Location -Path AD: -ErrorAction Stop
                    Write-Verbose "Connecting to default domain."
                }
                catch
                {
                    Write-Warning -Message ($LocalizedData.ADDefaultPSDriveError)
                    Pop-Location
                    throw $_
                }
            }
        }

        # retrieve hashtable of schema and access right GUIDs
        $schemaAndAccessRights = Get-ADObjectRightsGUID
        # variable used to store objectSID to account mappings
        $objectSIDs = @{}
        # variable used to store the resulting output
        $report = @()

        # make a record of the current location to private stack
        Push-Location -StackName 'Get-ADObjectAcl' -ErrorAction SilentlyContinue # keep a record of the current location
    }
    Process
    {
        $localLocationStack = (Get-Location -StackName 'Get-ADObjectAcl' -ErrorAction SilentlyContinue)
        if ((Get-Location).Path -ne $LocalLocationStack.Path)
        {
            Pop-Location -StackName 'Get-ADObjectAcl' -ErrorAction SilentlyContinue 
        }
        
        # determine whether a string or reference object has been passed
        if ($Identity -is "String")
        {
            Write-Verbose " Resolving String Identity Reference $Identity."
            try
            {
                $Identity = Get-ADObject -Identity $Identity -ErrorAction Stop
            }
            catch
            {
                Write-Warning -Message ($LocalizedData.IdentityNotFound -f $Identity)
                Write-Error $_
                Return $null
            }
        }
        else
        {
            if (($null -eq $Identity.DistinguishedName) -and ($null -eq $Identity.ObjectGUID))
            {
                Write-Warning -Message ($LocalizedData.IdentityTypeInvalid -f $Identity)
                Write-Error $_
                Return $null
            }
            Write-Verbose " Reference Identity $($Identity.ToString())."
        }

        # enumerate permissions on the Active Directory Object
        try
        {
            Write-Verbose " Extracting Access Control List."
            $Permissions = (Get-Acl -Path $Identity.DistinguishedName).Access    
        }
        catch
        {
            Write-Warning -Message ($LocalizedData.GetAclError -f ($Identity.DistinguishedName))
            Write-Error $_
            Return $null
        }
        
        forEach ($Permission in $Permissions)
        {
            $IdentityReferenceLabel = $null
            # extract the ObjectType and InheritedObjectType friendly names from the schemaAndAccessRights hash table from their GUIDs.
            $PermissionObjectTypeName = $schemaAndAccessRights.Item($Permission.ObjectType)
            $PermissionInheritedObjectTypeName = $schemaAndAccessRights.Item($Permission.InheritedObjectType)
            if ($Permission.IdentityReference -is [System.Security.Principal.SecurityIdentifier])
            {
                # certain Well Known SIDs don't seem to be resolved either by Get-Acl or using Translate()? And neither do SIDs from trusting Domains under certain circumstances
                # therefore a helper function is used to translate names for these; but first check that this SID hasn't previously been resolved
                if ($objectSIDs.ContainsKey($Permission.IdentityReference.Value))
                {
                    $IdentityReferenceLabel = $objectSIDs.($Permission.IdentityReference.Value)
                }
                else 
                {
                    try 
                    {
                        $IdentityReferenceLabel = (Resolve-ObjectSidToName -Sid $Permission.IdentityReference)
                    }
                    catch
                    {
                        # ignore errors returned by the Resolve-ObjectSidToName function and continue
                    }
                    
                    # add the resolved name to objectSIDs to prevent having to resolve the same SID again
                    $objectSIDs.Add($Permission.IdentityReference.Value, $IdentityReferenceLabel)
                }
            }
            else
            {
                $IdentityReferenceLabel = $Permission.IdentityReference
            }
            
            # filter the ACE items returned, based on the parameters which have been passed.
            if ($PSBoundParameters.ContainsKey('IsInherited'))
            {
                if ($Permission.IsInherited -ne $IsInherited)
                {
                    Continue
                }
            }
            if ($PSBoundParameters.ContainsKey('IdentityReference'))
            {
                if ($IdentityReferenceLabel -ne $IdentityReference)
                {
                    Continue
                }
            }
            if ($PSBoundParameters.ContainsKey('ActiveDirectoryRights'))
            {
                $PermissionActiveDirectoryRights = ($Permission.ActiveDirectoryRights -split ", ")
                if ($null -ne (Compare-Object -ReferenceObject $PermissionActiveDirectoryRights -DifferenceObject $ActiveDirectoryRights))
                {
                    Continue
                }
            }
            if ($PSBoundParameters.ContainsKey('ObjectTypeName'))
            {
                if ($ObjectTypeName -ne $PermissionObjectTypeName)
                {
                    Continue
                }
            }
            if ($PSBoundParameters.ContainsKey('InheritedObjectTypeName'))
            {
                if ($InheritedObjectTypeName -ne $PermissionInheritedObjectTypeName)
                {
                    Continue
                }
            }
            if ($PSBoundParameters.ContainsKey('InheritanceType'))
            {
                if ($InheritanceType -ne $Permission.InheritanceType)
                {
                    Continue
                }
            }
            if ($PSBoundParameters.ContainsKey('AccessControlType'))
            {
                if ($AccessControlType -ne $Permission.AccessControlType)
                {
                    Continue
                }
            }

            $reportItem = New-Object -TypeName "PSObject" -Property @{
                distinguishedName       = $Identity.DistinguishedName
                ActiveDirectoryRights   = ($Permission.ActiveDirectoryRights.ToString() -Split ", ")
                InheritanceType         = $Permission.InheritanceType
                ObjectType              = $Permission.ObjectType
                ObjectTypeName          = $PermissionObjectTypeName
                InheritedObjectType     = $Permission.InheritedObjectType
                InheritedObjectTypeName = $PermissionInheritedObjectTypeName
                ObjectFlags             = $Permission.ObjectFlags
                AccessControlType       = $Permission.AccessControlType
                IdentityReference       = $IdentityReferenceLabel
                IsInherited             = $Permission.IsInherited
                InheritanceFlags        = $Permission.InheritanceFlags
                PropagationFlags        = $Permission.PropagationFlags
            }
            $reportItem.PSObject.TypeNames.Insert(0, "cActiveDirectoryPermission.ACE")

            # apply additional filters for those properties associated with cActiveDirectoryPermission.ACE type
            if ($PSBoundParameters.ContainsKey('IdentityReferenceName'))
            {
                if ($reportItem.IdentityReferenceName -ne $IdentityReferenceName)
                {
                    Continue
                }
                Write-Verbose $IdentityReferenceName
            }
            if ($PSBoundParameters.ContainsKey('IdentityReferenceDomain'))
            {
                if ($reportItem.IdentityReferenceDomain -ne $IdentityReferenceDomain)
                {
                    Continue
                }
            }

            $report += $reportItem
        }
    }
    End
    {
        # no need to perform AD PSDrive clear down if the command is being called by another function within the same module
        if ( ((Get-PSCallStack)[0].Location).Split(":")[0] -ne ((Get-PSCallStack)[1].Location).Split(":")[0])
        {
            Pop-Location -StackName 'cActiveDirectorySecurity' -ErrorAction SilentlyContinue 
            if ($null -ne $PSDriveName)
            {
                Remove-PSDrive -Name $PSDriveName -Force # remove AD PSDrive if one was created
            }
        }

        if ($SendToClipboard)
        {
            $props = @("DistinguishedName"
                "IdentityReference" 
                "IdentityReferenceName"
                "IdentityReferenceDomain"
                @{n = "ActiveDirectoryRights"; e = {$_.ActiveDirectoryRights -Join ", "}}
                "ObjectType"
                "ObjectTypeName"
                "InheritedObjectType"
                "InheritedObjectTypeName"
                "AccessControlType"
                "PropagationFlags"
                "IsInherited"
                "InheritanceFlags"
                "ObjectFlags"
                "InheritanceType"
            )
            # send output to clipboard in tab delimited format (can be pasted directly into Microsoft Excel)
            if ($PSVersionTable.PSVersion.Major -lt 5)
            {
                $report | Select-Object $props | ConvertTo-Csv -Delimiter "`t" -NoTypeInformation | Clip.exe
            }
            else
            {
                $report | Select-Object $props | ConvertTo-Csv -Delimiter "`t" -NoTypeInformation | Set-Clipboard    
            }
        }
        else
        {
            Return $report
        }
    }
}

<#
.Synopsis
    Adds a new Access Control Entry to an  Access Control List defined on an Active Directory Object.
.DESCRIPTION
    Adds a new Access Control Entry (ACE) to an Access Control List (ACL) defined on an Active Directory Object.

.EXAMPLE
    Add-ADObjectAce -Identity "OU=Users,OU=GB,DC=contoso,DC=com" -IdentityReference "CONTOSO\GB User Management" -ActiveDirectoryRights ReadProperty,WriteProperty -ObjectTypeName Description -InheritedObjectTypeName User -InheritanceType Descendents -WhatIf

    Adds a new ACE to ACL on AD object "OU=Users,OU=GB,DC=contoso,DC=com" for the Identity Reference "CONTOSO\GB User Management" with Active Directory Rights "ReadProperty", "WriteProperty" for the Object Type with Name "Description" and "InheritedObjectType" of Name "User" propagated to "Descendants".

    As the -WhatIf parameter is specified the format of the new ACE is displayed, without being applied.
.EXAMPLE
    Add-ADObjectAce -Identity "OU=Users,OU=GB,DC=contoso,DC=com" -IdentityReference "CONTOSO\GB User Management" -ActiveDirectoryRights ReadProperty,WriteProperty -ObjectTypeName Description -InheritedObjectTypeName User -InheritanceType Descendents -Server dc1.contoso.com

    Adds a new ACE to ACL on AD object "OU=Users,OU=GB,DC=contoso,DC=com" for the Identity Reference "CONTOSO\GB User Management" with Active Directory Rights "ReadProperty", "WriteProperty" for the Object Type with Name "Description" and "InheritedObjectType" of Name "User" propagated to "Descendants" targeting Domain Controller "dc1.contoso.com".

    User is prompted for confirmation.
.EXAMPLE
    Add-ADObjectAce -Identity "OU=Users,OU=GB,DC=contoso,DC=com" -IdentityReference "CONTOSO\GB User Management" -ActiveDirectoryRights ReadProperty,WriteProperty -ObjectTypeName Description -InheritedObjectTypeName User -InheritanceType Descendents -Server dc1.contoso.com -Credential $Credential -Force

    Adds a new ACE to ACL on AD object "OU=Users,OU=GB,DC=contoso,DC=com" for the Identity Reference "CONTOSO\GB User Management" with Active Directory Rights "ReadProperty", "WriteProperty" for the Object Type with Name "Description" and "InheritedObjectType" of Name "User" propagated to "Descendants" targeting Domain Controller "dc1.contoso.com" with the specified credentials.

    As the -Force parameter is specified, the user is not prompted for confirmation.
.EXAMPLE
    Get-ADUser -Filter {department -like "Marketing"} | Add-ADObjectAce -IdentityReference "CONTOSO\Marketing Support Team"  -ActiveDirectoryRights ReadProperty,WriteProperty -ObjectTypeName "Private-Information" -InheritanceType All -WhatIf

    Retrieves all users with a department value of "Marketing" and adds a new ACE to ACL for the Identity Reference "CONTOSO\Marketing Support Team" with Active Directory Rights "ReadProperty", "WriteProperty" for the Object Type with Name "Private-Information" and "InheritanceType" of "All".

    As the -WhatIf parameter is specified the format of the new ACE is displayed, without being applied.
.INPUTS
   The identity parameter of the CmdLet accepts either a distinguishedName or ObjectGUID or AD Objects. AD Objects which are passed by reference must include either a distinguishedName or ObjectGUID property.
.OUTPUTS
   None unless -WhatIf parameter is used in which case a cActiveDirectoryPermission.ACE object is returned.
#>
function Add-ADObjectAce
{
    [CmdletBinding(SupportsShouldProcess = $true, PositionalBinding = $false, ConfirmImpact = 'High')]
    [OutputType([Object])]
    Param(
        # The Identity of the Active Directory Object in either distinguishedName or GUID format or by reference.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false)]
        [object]$Identity,
        
        # The target Active Directory Server / Domain Controller.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [string]$Server,

        # The IdentityReference that will be defined on the ACE (DOMAIN\USERNAME).
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [string]
        $IdentityReference,

        # The Active Directory Rights that will be defined on the ACE.
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [ValidateSet( "CreateChild", "DeleteChild", "ListChildren", "Self", "ReadProperty", "WriteProperty", "DeleteTree", "ListObject", "ExtendedRight", "Delete", "ReadControl", "GenericExecute", "GenericWrite", "GenericRead", "WriteDacl", "WriteOwner", "GenericAll", "Synchronize", "AccessSystemSecurity")]
        [string[]]
        $ActiveDirectoryRights,

        # The Object Type Name that will be defined on the ACE.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [string]
        $ObjectTypeName,

        # The Inherited Object Type Name that will be defined on the ACE.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [string]
        $InheritedObjectTypeName,

        # The Access Control Type (Allow / Deny) that will be defined on the ACE.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [ValidateSet("Allow", "Deny")]
        [string]
        $AccessControlType = "Allow",

        # The Inheritance Type that will be defined on the ACE.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [ValidateSet("All", "Children", "Descendents", "None", "SelfAndChildren")]
        [string]
        $InheritanceType,

        # Credential to use.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [System.Management.Automation.PSCredential]
        $Credential,

        # Ignore any should process warnings and apply the new Ace.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [switch]
        $Force
    )
    Begin
    {
        Push-Location # keep a record of the current location

        $PSDriveParams = @{"ErrorAction" = "Stop"}
        
        if ($PSBoundParameters.ContainsKey('Credential'))
        {
            $PSDriveParams.Add("Credential", $Credential)
        }
        if ($PSBoundParameters.ContainsKey('Server'))
        {
            $PSDriveParams.Add("Server", $Server)
        }
        else 
        {
            $Server = (Get-AdDomain).NetBIOSName
        }

        if (($PSBoundParameters.ContainsKey('Server')) -or ($PSBoundParameters.ContainsKey('Credential')))
        {
            try
            {
                # create a new PSDrive to the target AD Domain Controller / or using different credentials
                $PSDriveName = $Server.Split(".")[0]
                New-PSDrive -Name $PSDriveName -PSProvider ActiveDirectory -root "//RootDSE/" @PSDriveParams -WhatIf:$false | Out-Null
                Set-Location ($PSDriveName + ":") -ErrorAction Stop
                Write-Verbose "Connecting to specified server / domain controller."
                Write-Verbose -Message "Server: $Server"
            }
            catch
            {
                Write-Warning -Message ($LocalizedData.ADPSDriveError -f $Server)
                Pop-Location
                throw $_
            }
        }
        else
        {
            # connect to the default Active Directory PSDrive
            try
            {
                Set-Location -Path AD: -ErrorAction Stop
                Write-Verbose "Connecting to default domain."
            }
            catch
            {
                Write-Warning -Message ($LocalizedData.ADDefaultPSDriveError)
                Pop-Location
                throw $_
            }
        }
    }
    Process
    {
        # determine whether a string or reference object has been passed
        if ($Identity -is "String")
        {
            Write-Verbose " Resolving String Identity Reference $Identity."
            try
            {
                $Identity = Get-ADObject -Identity $Identity -ErrorAction Stop
            }
            catch
            {
                Write-Warning -Message ($LocalizedData.IdentityNotFound -f $Identity)
                Write-Error $_
                Return $null
            }
        }
        else
        {
            if (($null -eq $Identity.DistinguishedName) -and ($null -eq $Identity.ObjectGUID))
            {
                Write-Warning -Message ($LocalizedData.IdentityTypeInvalid -f $Identity)
                Write-Error $_
                Return $null
            }
            Write-Verbose " Reference Identity $($Identity.ToString())."
        }

        # list of parameters that will passed to the constructor of new ace
        $NewAceParams = @()

        # convert the Identity Reference into a System.Security.Principal.SecurityIdentifier
        try
        {
            $sid = (Resolve-NameToObjectSid -IdentityReference $IdentityReference)
            $NewAceParams += $sid    
        }
        catch
        {
            Write-Error $_
            Return $null
        }

        # the $sid of the $IdentityReference is mandatory in order to generate the new ACE
        if ($null -eq $sid)
        {
            Write-Warning -Message ($LocalizedData.IdentityReferenceInvalid -f $IdentityReference)
            Return $null
        }
        else 
        {
            Write-Verbose " Identity Reference $($IdentityReference.distinguishedName) translated to Sid value ($Sid)."
        }
        
        # convert ActiveDirectoryRights into ActiveDirectoryRights Object for generating the Ace
        $ActiveDirectoryRightsObject = [System.DirectoryServices.ActiveDirectoryRights]$ActiveDirectoryRights
        $NewAceParams += $ActiveDirectoryRightsObject
        # convert the AccessControlType into AccessControlType for generating the Ace
        $AccessControlTypeObject = [System.Security.AccessControl.AccessControlType]$AccessControlType
        $NewAceParams += $AccessControlTypeObject

        if ($PSBoundParameters.ContainsKey('ObjectTypeName'))
        {
            Write-Verbose " ObjectTypeName $ObjectTypeName has been passed."
            try
            {
                # retrieve the object Type Guid
                $ObjectType = Get-ADObjectRightsGUID -Name $ObjectTypeName
            }
            catch 
            {
                Write-Error $_
                Return $null
            }

            if ($null -eq $ObjectType)
            {
                Write-Warning -Message ($LocalizedData.ObjectTypeNameNotFound -f ($ObjectTypeName))
                Return $null
            }
            else 
            {
                $ObjectTypeGUID = $ObjectType.Keys | Select-Object -First 1
                Write-Verbose " ObjectTypeName of $ObjectTypeName resolved to GUID $ObjectTypeGUID."
                $NewAceParams += $ObjectTypeGUID
            }
        }

        if ($PSBoundParameters.ContainsKey('InheritanceType'))
        {
            Write-Verbose " InheritanceType $InheritanceType has been passed."
            # convert the InheritanceType into ActiveDirectorySecurityInheritance Object for generating the Ace (if the parameter has been passed)
            $InheritanceTypeObject = [System.DirectoryServices.ActiveDirectorySecurityInheritance]$InheritanceType
            $NewAceParams += $InheritanceTypeObject
        }

        if ($PSBoundParameters.ContainsKey('InheritedObjectTypeName'))
        {
            Write-Verbose " InheritedObjectTypeName $InheritedObjectTypeName has been passed."
            try
            {
                # retrieve the inherited object type Guid
                $InheritedObjectType = Get-ADObjectRightsGUID -Name $InheritedObjectTypeName
            }
            catch 
            {
                Write-Error $_
                Return $null
            }

            if ($null -eq $InheritedObjectType)
            {
                Write-Warning -Message ($LocalizedData.InheritedObjectTypeNameNotFound -f ($InheritedObjectTypeName))
                Return $null
            }
            else 
            {
                $InheritedObjectTypeGUID = $InheritedObjectType.Keys | Select-Object -First 1
                Write-Verbose " InheritedObjectTypeName of $InheritedObjectTypeName resolved to GUID $InheritedObjectTypeGUID."
                $NewAceParams += $InheritedObjectTypeGUID
            }
        }
        
        # create the new ACE
        try 
        {
            Write-Verbose " Creating new ACE."
            $Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($NewAceParams)
        }
        catch
        {
            Write-Warning -Message ($LocalizedData.CreateNewAceError -f $Identity.DistinguishedName)
            Write-Error $_
            Return $null   
        }

        if ($Force -or $pscmdlet.ShouldProcess($Identity.DistinguishedName, "Add new Access Control Entry."))
        {
            # retrieve existing ACL permissions from the Active Directory Object
            Write-Verbose " Retrieving existing ACL."
            try
            {
                $Permissions = Get-Acl -Path $Identity.DistinguishedName
            }
            catch
            {
                Write-Warning -Message ($LocalizedData.GetAclError -f ($Identity.DistinguishedName))
                Write-Error $_
                Return $null
            }

            # add the new Ace to the Acl
            try
            {
                Write-Verbose " Adding new ACE to existing ACL."
                $Permissions.AddAccessRule($Ace)    
            }
            catch
            {
                Write-Warning -Message ($LocalizedData.AddAceError -f ($Identity.DistinguishedName))
                Write-Error $_
                Return $null
            }
        
            # finally re-apply the updated Acl to the object
            try
            {
                Write-Verbose " Applying the updated ACL to the AD object."
                Set-Acl -AclObject $Permissions -Path $Identity -ErrorAction Stop
            }
            catch
            {
                Write-Warning -Message ($LocalizedData.SetAclError -f ($Identity.DistinguishedName))
                Write-Error $_
                Return $null
            }
        }
        else
        {
            # otherwise simply output the generated $Ace for review
            $AceToOutput = New-Object -TypeName "PSObject" -Property @{
                distinguishedName       = $Identity.DistinguishedName
                ActiveDirectoryRights   = ($Ace.ActiveDirectoryRights.ToString() -Split ", ")
                InheritanceType         = $Ace.InheritanceType
                ObjectType              = $Ace.ObjectType
                ObjectTypeName          = (Get-ADObjectRightsGUID -GUID $Ace.ObjectType | Select-Object -ExpandProperty Values | Select-Object -First 1)
                InheritedObjectType     = $Ace.InheritedObjectType
                InheritedObjectTypeName = (Get-ADObjectRightsGUID -GUID $Ace.InheritedObjectType | Select-Object -ExpandProperty Values | Select-Object -First 1)
                ObjectFlags             = $Ace.ObjectFlags
                AccessControlType       = $Ace.AccessControlType
                IdentityReference       = $IdentityReference
                IsInherited             = $Ace.IsInherited
                InheritanceFlags        = $Ace.InheritanceFlags
                PropagationFlags        = $Ace.PropagationFlags
            }
            $AceToOutput.PSObject.TypeNames.Insert(0, "cActiveDirectoryPermission.ACE")
            Write-Output $AceToOutput
        }
    }
    End
    {
        Pop-Location # return to original location
        if ($null -ne $PSDriveName)
        {
            Remove-PSDrive -Name $PSDriveName -Force -WhatIf:$false # remove AD PSDrive if one was created
        }
    }
}

<#
.Synopsis
    Removes an Access Control Entry from an Access Control List defined on an Active Directory Object.
.DESCRIPTION
    Removes an Access Control Entry (ACE) from an Access Control List (ACL) defined an Active Directory Object.

.EXAMPLE
    Remove-ADObjectAce -Identity "OU=Users,OU=GB,DC=contoso,DC=com" -IdentityReference "CONTOSO\GB User Management" -ActiveDirectoryRights ReadProperty,WriteProperty -ObjectTypeName Description -InheritedObjectTypeName User -InheritanceType Descendents -WhatIf

    Removes the ACE from the ACL on AD object "OU=Users,OU=GB,DC=contoso,DC=com" for the Identity Reference "CONTOSO\GB User Management" with Active Directory Rights "ReadProperty", "WriteProperty" for the Object Type with Name "Description" and "InheritedObjectType" of Name "User" propagated to "Descendants".

    As the -WhatIf parameter is specified the details of the existing ACE are displayed, without being removed.
.EXAMPLE
    Remove-ADObjectAce -Identity "OU=Users,OU=GB,DC=contoso,DC=com" -IdentityReference "CONTOSO\GB User Management" -ActiveDirectoryRights ReadProperty,WriteProperty -ObjectTypeName Description -InheritedObjectTypeName User -InheritanceType Descendents -Server dc1.contoso.com

    Remove the ACE from the ACL on AD object "OU=Users,OU=GB,DC=contoso,DC=com" for the Identity Reference "CONTOSO\GB User Management" with Active Directory Rights "ReadProperty", "WriteProperty" for the Object Type with Name "Description" and "InheritedObjectType" of Name "User" propagated to "Descendants" targeting Domain Controller "dc1.contoso.com".

    User is prompted for confirmation.
.EXAMPLE
    Remove-ADObjectAce -Identity "OU=Users,OU=GB,DC=contoso,DC=com" -IdentityReference "CONTOSO\GB User Management" -ActiveDirectoryRights ReadProperty,WriteProperty -ObjectTypeName Description -InheritedObjectTypeName User -InheritanceType Descendents -Server dc1.contoso.com -Credential $Credential -Force

    Removes the ACE from the ACL on AD object "OU=Users,OU=GB,DC=contoso,DC=com" for the Identity Reference "CONTOSO\GB User Management" with Active Directory Rights "ReadProperty", "WriteProperty" for the Object Type with Name "Description" and "InheritedObjectType" of Name "User" propagated to "Descendants" targeting Domain Controller "dc1.contoso.com" with the specified credentials.

    As the -Force parameter is specified, the user is not prompted for confirmation.
.EXAMPLE
    Get-ADObjectAcl -Identity "OU=Users,OU=GB,DC=contoso,DC=com" -IdentityReference "CONTOSO\GB User Management" | Remove-ADObjectAce -Force

    Removes all matching ACEs from ACL on object "OU=Users,OU=GB,DC=contoso,DC=com" for the Identity Reference "CONTOSO\GB User Management".

    As the -Force parameter is specified, the user is not prompted for confirmation.
.INPUTS
   The identity parameter of the CmdLet accepts either a distinguishedName or ObjectGUID or AD Objects. AD Objects which are passed by reference must include either a distinguishedName or ObjectGUID property.
.OUTPUTS
   None unless -WhatIf parameter is used in which case a cActiveDirectoryPermission.ACE object is returned.
#>
function Remove-ADObjectAce
{
    [CmdletBinding(SupportsShouldProcess = $true, PositionalBinding = $false, ConfirmImpact = 'High')]
    [OutputType([Object])]
    Param(
        # The Identity of the Active Directory Object in either distinguishedName or GUID format or by reference.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false)]
        [object]
        $Identity,
        
        # The target Active Directory Server / Domain Controller.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [string]
        $Server,

        # The IdentityReference defined on the ACE (DOMAIN\USERNAME) to be removed.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $IdentityReference,

        # The Active Directory Rights defined on the ACE to be removed.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet( "CreateChild", "DeleteChild", "ListChildren", "Self", "ReadProperty", "WriteProperty", "DeleteTree", "ListObject", "ExtendedRight", "Delete", "ReadControl", "GenericExecute", "GenericWrite", "GenericRead", "WriteDacl", "WriteOwner", "GenericAll", "Synchronize", "AccessSystemSecurity")]
        [string[]]
        $ActiveDirectoryRights,

        # The Object Type Name defined on the ACE to be removed.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]
        $ObjectTypeName,

        # The Inherited Object Type Name defined on the ACE to be removed.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]
        $InheritedObjectTypeName,

        # The Access Control Type (Allow / Deny) defined on the ACE to be removed.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("Allow", "Deny")]
        [string]
        $AccessControlType = "Allow",

        # The Inheritance Type defined on the ACE to be removed.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("All", "Children", "Descendents", "None", "SelfAndChildren")]
        [string]
        $InheritanceType,

        # Credential to use.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [System.Management.Automation.PSCredential]
        $Credential,

        # Ignore any should process warnings and remove the matching Ace.
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [switch]
        $Force
    )
    Begin
    {
        # make a record of the initial location stack
        $locationStack = (Get-Location -StackName "cActiveDirectorySecurity" -ErrorAction SilentlyContinue)
        if ($locationStack.count -eq 0)
        {
            Push-Location -StackName 'CActiveDirectorySecurity' -ErrorAction SilentlyContinue # keep a record of the current location    
        }
        else
        {
            Set-Location -Path ($locationStack.Path[0]) -ErrorAction SilentlyContinue
            Push-Location -StackName 'CActiveDirectorySecurity' -Path ($locationStack.Path[0]) -ErrorAction SilentlyContinue
        }
                       
        $PSDriveParams = @{"ErrorAction" = "Stop"}
        
        if ($PSBoundParameters.ContainsKey('Credential'))
        {
            $PSDriveParams.Add("Credential", $Credential)
        }
        if ($PSBoundParameters.ContainsKey('Server'))
        {
            $PSDriveParams.Add("Server", $Server)
        }
        else 
        {
            $Server = (Get-AdDomain).NetBIOSName
        }

        if (($PSBoundParameters.ContainsKey('Server')) -or ($PSBoundParameters.ContainsKey('Credential')))
        {
            try
            {
                # create a new PSDrive to the target AD Domain Controller / or using different credentials
                $PSDriveName = $Server.Split(".")[0]
                New-PSDrive -Name $PSDriveName -PSProvider ActiveDirectory -root "//RootDSE/" @PSDriveParams -WhatIf:$false | Out-Null
                Set-Location ($PSDriveName + ":") -ErrorAction Stop
                Write-Verbose "Connecting to specified server / domain controller."
                Write-Verbose -Message "Server: $Server"
            }
            catch
            {
                Write-Warning -Message ($LocalizedData.ADPSDriveError -f $Server)
                Pop-Location
                throw $_
            }
        }
        else
        {
            # connect to the default Active Directory PSDrive
            try
            {
                Set-Location -Path AD: -ErrorAction Stop
                Write-Verbose "Connecting to default domain."
            }
            catch
            {
                Write-Warning -Message ($LocalizedData.ADDefaultPSDriveError)
                Pop-Location
                throw $_
            }
        }

        # make a record of the current location to private stack
        Push-Location -StackName 'Remote-ADObjectAce' -ErrorAction SilentlyContinue # keep a record of the current location
    }
    Process
    {
        $LocalLocationStack = (Get-Location -StackName 'Remote-ADObjectAce' -ErrorAction SilentlyContinue)
        if ((Get-Location).Path -ne ($LocalLocationStack.Path))
        {
            Pop-Location -StackName 'Remote-ADObjectAce' -ErrorAction SilentlyContinue 
        }

        # where the Get-ADObjectAcl function is used to feed this function the reference object passed will be of type cActiveDirectoryPermission.ACE
        # therefore ensure it gets converted to an appropriate AD object
        if ("Get-ADObjectAcl" -eq (Get-PSCallStack)[1].Command)
        {
            $Identity = $Identity.DistinguishedName.ToString()
        }

        # determine whether a string or reference object has been passed
        if ($Identity -is "String")
        {
            Write-Verbose " Resolving String Identity Reference $Identity."
            try
            {
                $Identity = Get-ADObject -Identity $Identity -ErrorAction Stop
            }
            catch
            {
                Write-Warning -Message ($LocalizedData.IdentityNotFound -f $Identity)
                Write-Error $_
                Return $null
            }
        }
        else
        {
            if (($null -eq $Identity.DistinguishedName) -and ($null -eq $Identity.ObjectGUID))
            {
                Write-Warning -Message ($LocalizedData.IdentityTypeInvalid -f $Identity)
                Write-Error $_
                Return $null
            }
            Write-Verbose " Reference Identity $($Identity.ToString())."
        }

        # build param list to pass to Get-ADObjectAcl
        $GetADObjectAclParams = $PSBoundParameters
        if ($GetADObjectAclParams.ContainsKey('WhatIf')) { $GetADObjectAclParams.Remove("WhatIf") | Out-Null }
        if ($GetADObjectAclParams.ContainsKey('Identity')) { $GetADObjectAclParams.Remove("Identity") | Out-Null }
        if ($GetADObjectAclParams.ContainsKey('Force')) { $GetADObjectAclParams.Remove("Force") | Out-Null }
        if (-Not ($GetADObjectAclParams.ContainsKey('Identity'))) { $GetADObjectAclParams.Add("Identity", $Identity) | Out-Null }
        if (-Not ($GetADObjectAclParams.ContainsKey('IsInherited'))) { $GetADObjectAclParams.Add("IsInherited", $False) | Out-Null }

        # confirm that the ACE to remove is actually present - using Get-ADObjectAcl
        try 
        {
            $Ace = Get-ADObjectAcl @GetADObjectAclParams
        }
        catch
        {
            Write-Error $_
            Return $null
        }

        # no ACE found matching the specified filter 
        if ($null -eq $Ace)
        {
            Write-Warning -Message ($LocalizedData.AceNotFound -F $Identity)
            Return $null
        }

        # count the number of ACE objects returned (should only be one present that matches the filter parameters passed!)
        if ($null -ne $Ace.Count -and $Ace.Count -gt 1)
        {
            Write-Warning -Message ($LocalizedData.MultipleAceValuesFound -F $Identity, ($Ace.Count))
            Return $null
        }

        # retrieve existing ACL permissions from the Active Directory Object
        Write-Verbose " Retrieving existing ACL."
        try
        {
            $Permissions = Get-Acl -Path $Identity -ErrorAction Stop
        }
        catch
        {
            Write-Warning -Message ($LocalizedData.GetAclError -f ($Identity))
            Write-Error $_
            Return $null
        }

        # find a matching ACE within the ACL
        $MatchedAce = $null
        forEach ($Permission in $Permissions.Access)
        {
            
            if ($Permission.ActiveDirectoryRights -ne $Ace.ActiveDirectoryRights)
            {
                Continue
            }
            If ($Permission.ObjectType -ne $Ace.ObjectType)
            {
                Continue
            }
            If ($Permission.InheritedObjectType -ne $Ace.InheritedObjectType)
            {
                Continue
            }
            If ($Permission.AccessControlType -ne $Ace.AccessControlType)
            {
                Continue
            }
            if ($Permission.PropagationFlags -ne $Ace.PropagationFlags)
            {
                Continue
            }
            if ($Permission.IsInherited -ne $Ace.IsInherited)
            {
                Continue
            }
            If ($Permission.ObjectFlags -ne $Ace.ObjectFlags)
            {
                Continue
            }
            If ($Permission.InheritanceFlags -ne $Ace.InheritanceFlags)
            {
                Continue
            }
            if ($Permission.IdentityReference -is [System.Security.Principal.SecurityIdentifier])
            {
                $IdentityReferenceLabel = (Resolve-ObjectSidToName -Sid $Permission.IdentityReference)

                if ($IdentityReferenceLabel -ne $Ace.IdentityReference)
                {
                    Continue
                }
            }
            elseIf ($Permission.IdentityReference -ne $Ace.IdentityReference)
            {
                Continue
            }

            # if we reach this point we have a match
            $MatchedAce = $Permission
            Break
        }

        if ($null -eq $MatchedAce)
        {
            Write-Warning -Message ($LocalizedData.MatchingAceNotFound -f ($Identity.DistinguishedName))
            Return $null
        }

        if ($Force -or $pscmdlet.ShouldProcess($Identity.DistinguishedName, "Removing matching Access Control Entry from the ACL."))
        {
            # remove the new Ace from the Acl
            try
            {
                Write-Verbose " Removing matching ACE from the existing ACL."
                $Permissions.RemoveAccessRuleSpecific($MatchedAce)    
            }
            catch
            {
                Write-Warning -Message ($LocalizedData.RemoveAceError -f ($Identity))
                Write-Error $_
                Return $null
            }
        
            # finally re-apply the updated Acl to the object
            try
            {
                Write-Verbose " Applying the updated ACL to the AD object."
                Set-Acl -AclObject $Permissions -Path $Identity -ErrorAction Stop
            }
            catch
            {
                Write-Warning -Message ($LocalizedData.ClearAclError -f $Identity)
                Write-Error $_
                Return $null
            }
        }
        else
        {
            # otherwise simply output the generated $Ace for review
            $AceToOutput = New-Object -TypeName "PSObject" -Property @{
                DistinguishedName       = $Identity.DistinguishedName
                ActiveDirectoryRights   = ($MatchedAce.ActiveDirectoryRights.ToString() -Split ", ")
                InheritanceType         = $MatchedAce.InheritanceType
                ObjectType              = $MatchedAce.ObjectType
                ObjectTypeName          = (Get-ADObjectRightsGUID -GUID $MatchedAce.ObjectType | Select-Object -ExpandProperty Values | Select-Object -First 1)
                InheritedObjectType     = $MatchedAce.InheritedObjectType
                InheritedObjectTypeName = (Get-ADObjectRightsGUID -GUID $MatchedAce.InheritedObjectType | Select-Object -ExpandProperty Values | Select-Object -First 1)
                ObjectFlags             = $MatchedAce.ObjectFlags
                AccessControlType       = $MatchedAce.AccessControlType
                IdentityReference       = $IdentityReference
                IsInherited             = $MatchedAce.IsInherited
                InheritanceFlags        = $MatchedAce.InheritanceFlags
                PropagationFlags        = $MatchedAce.PropagationFlags
            }
            $AceToOutput.PSObject.TypeNames.Insert(0, "cActiveDirectoryPermission.ACE")
            Write-Output $AceToOutput
        }
    }
    End
    {
        Pop-Location -StackName 'cActiveDirectorySecurity' # return to original location
        if ($null -ne $PSDriveName)
        {
            Remove-PSDrive -Name $PSDriveName -Force -WhatIf:$false # remove AD PSDrive if one was created
        }
    }
}

<#
.Synopsis
   Get list of AD Object GUIDs and Access Right GUIDs from Active Directory.
.DESCRIPTION
   Get a complete list of AD Object GUIDs and Access Rights GUIDs from either the default or specified Active Directory Forest / Domain.
.EXAMPLE
   Get-ADObjectRightsGUID

   Gets a complete list of AD Object GUIDs and Access Rights GUIDs from the default Active Directory Forest / Domain.
.EXAMPLE
   Get-ADObjectRightsGUID -Name 'Computer'

   Gets the Schema Object with the Name 'Computer'
.EXAMPLE
   Get-ADObjectRightsGUID -Name 'Personal-Information'

   Gets the Extended Right / controlAccessRight with the Name 'Personal-Information'
.INPUTS
   The (optional) hostname of a target Server / Domain Controller.
.OUTPUTS
   Outputs a hashtable of AD Object GUIDs and their associated names.

#>
function Get-ADObjectRightsGUID
{
    [CmdletBinding(DefaultParameterSetName = 'None',
        SupportsShouldProcess = $false,
        PositionalBinding = $false)]
    [OutputType([Object[]])]
    Param
    (
        # the Name of the schema object or control access right to retrieve
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ParameterSetName = 'Name')]
        [string]$Name,

        # the GUID of the schema object or control access right to retrieve
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ParameterSetName = 'GUID')]
        [object]$GUID
    )
    Begin
    {
    }
    Process
    {
        # thanks to https://blogs.technet.microsoft.com/ashleymcglone/2013/03/25/active-directory-ou-permissions-report-free-powershell-script-download/ for much of this
        # retrieve details of schema GUIDs and Access Rights from the schema and the configuration naming contexts
        # note that these queries will be targeted to the correct domain as we have already switched to the correct AD PSdrive
        try
        {
            $rootDSE = Get-ADRootDSE
            $schemaNamingContext = ($rootDSE.schemaNamingContext)
            Write-Verbose -Message "schemaNamingContext: $schemaNamingContext"
            $configurationNamingContext = ($rootDSE.configurationNamingContext)
            Write-Verbose -Message "configurationNamingContext: $configurationNamingContext"
        }
        catch
        {
            Write-Warning -Message ($LocalizedData.RootDSEError -f $DomainName)
            Pop-Location         
            throw $_
        }

        $schemaAndAccessRights = @{}
        
        switch ($PSCmdlet.ParameterSetName)
        {
            'Name' 
            {
                if ("All" -eq $Name)
                {
                    $schemaAndAccessRights.Add([System.GUID]'00000000-0000-0000-0000-000000000000', 'All')
                }
                else 
                {
                    try
                    {
                        $schemaObjects = Get-ADObject -SearchBase $schemaNamingContext -LDAPFilter "(&(schemaIDGUID=*)(Name=$Name))" -Properties name, schemaIDGUID
                    }
                    catch
                    {
                        # ignore errors
                    }

                    try
                    {
                        $accessRights = Get-ADObject -SearchBase "CN=Extended-Rights,$configurationNamingContext" -LDAPFilter "(&(objectClass=controlAccessRight)(Name=$Name))" -Properties name, rightsGUID 
                    }
                    catch
                    {
                        # ignore errors 
                    }

                    if (($null -eq $schemaObjects) -and ($null -eq $accessRights))
                    {
                        Return $null
                    }
                }
            }
            'GUID' 
            {
                # determine whether a string or GUID value has been passed
                if (($GUID -is [GUID]) -or ($GUID -is [String]))
                {
                    if ($GUID -is [String])
                    {
                        $GUID = [GUID]$GUID
                    }
                    if ([GUID]"00000000-0000-0000-0000-000000000000" -eq $GUID)
                    {
                        $schemaAndAccessRights.Add([System.GUID]'00000000-0000-0000-0000-000000000000', 'All')
                    }
                    else
                    {
                        try
                        {
                            $schemaObjects = Get-ADObject -SearchBase $schemaNamingContext -Filter {schemaIDGUID -eq $GUID} -Properties name, schemaIDGUID
                        }
                        catch
                        {
                            # ignore errors
                        }

                        try
                        {
                            $accessRights = Get-ADObject -SearchBase "CN=Extended-Rights,$configurationNamingContext" -Filter {rightsGUID -eq $GUID} -Properties name, rightsGUID 
                        }
                        catch
                        {
                            # ignore errors 
                        }

                        if (($null -eq $schemaObjects) -and ($null -eq $accessRights))
                        {
                            Return $null
                        }
                    }
                }
                else
                {
                    Return $null
                }
            }
            Default
            {
                $schemaAndAccessRights.Add([System.GUID]'00000000-0000-0000-0000-000000000000', 'All')
                $schemaObjects = Get-ADObject -SearchBase $schemaNamingContext -LDAPFilter '(schemaIDGUID=*)' -Properties name, schemaIDGUID 
                $accessRights = Get-ADObject -SearchBase "CN=Extended-Rights,$configurationNamingContext" -LDAPFilter '(objectClass=controlAccessRight)' -Properties name, rightsGUID 
            }
        }
        
        ForEach ($schemaObject in $schemaObjects)
        {
            try
            {
                $schemaAndAccessRights.Add([System.GUID]$schemaObject.schemaIDGUID, $schemaObject.name)
            }
            catch
            {
                # ignore errors
            }
        }
        ForEach ($accessRight in $accessRights)
        {
            try
            {
                $schemaAndAccessRights.Add([System.GUID]$accessRight.rightsGUID, $accessRight.name)
            }
            catch
            {
                # ignore errors
            }
        }

        Return $schemaAndAccessRights
    }
    End
    {
    }
}


<#
.Synopsis
   Resolves an object SID to an associated Windows Accounts or Security Principal.
.DESCRIPTION
   Resolves an object SID to an associated Windows Account or Security Principal using an Active Directory Web Services query. As the function was created as a utility function, it is assumged that
   (when resolving SIDs from the non-default domain) that an AD PSDrive has already been established with the external Domain and have changed directory to that PSDrive.
.EXAMPLE
   $stringsid= "S-1-5-32-554"
   $sid = new-object security.principal.securityidentifier($stringsid)

   Resolve-ObjectSidToName -Sid $sid

   Returns the name 'BUILTIN\Pre-Windows 2000 Compatible Access' for the SID with string value 'S-1-5-32-554'.
.EXAMPLE
   $stringsid= "S-1-5-21-2295585024-2604479722-1786026388-512"
   $sid = new-object security.principal.securityidentifier($stringsid)

   Resolve-ObjectSidToName -Sid $sid

   Returns the name 'CONTOSO\Domain Admins' for the SID with string value 'S-1-5-21-2295585024-2604479722-1786026388-512'.
.INPUTS
   A [System.Security.Principal.SecurityIdentifier] object.
.OUTPUTS
   Output the name associated Windows Accounts or Security Principal, otherwise returns the original (unresolved) Sid.
#>
function Resolve-ObjectSidToName
{
    [CmdletBinding(SupportsShouldProcess = $false, 
        PositionalBinding = $true)]
    [OutputType([Object])]
    Param
    (
        # The security identifier to translate
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false, Position = 0)]
        [System.Security.Principal.IdentityReference]
        $Sid
    )
    Begin
    {
    }
    Process
    {
        Write-Verbose "Resolving sid $Sid..."

        # names are resolved using Get-AdObject. Ideally would prefer to use something like Translate([System.Security.Principal.NTAccount]) but doesn't work very well
        # with anything but the current domain or with BUILTIN security principals and don't really want to maintain tables of well-known-sids

        try
        {
            # build param list to splat to Get-ADObject
            $GetADObjectParams = @{"filter" = ("objectSid -eq " + '"' + $Sid + '"' + ""); "properties" = "sAMAccountName"; "ErrorAction" = "Stop"}
            $ADObject = Get-AdObject @GetADObjectParams
        }
        catch
        {
            Write-Warning -Message ($LocalizedData.GetADObjectSidError -f ($sid.Value))
            throw $_
        } 

        if ($null -ne $ADObject)
        {
            # if object is located in the Builtin container then return BUILTIN\sAMAccountName
            if ($ADObject.DistinguishedName -match ",(?<Builtin>CN=Builtin,DC=.*$)")
            {
                Write-Verbose ("BUILTIN\" + $ADObject.sAMAccountName)
                Return ("BUILTIN\" + $ADObject.sAMAccountName)
            }
            # otherwise return NetBIOSName\sAMAccountName
            else
            {
                try
                {
                    $DomainNetBIOSName = (Get-ADDomain).NetBIOSName
                }
                catch
                {
                    Write-Warning -Message ($LocalizedData.NetBIOSDomainError)
                } 
                
                if ($null -ne $DomainNetBIOSName)
                {
                    Write-Verbose ("$DomainNetBIOSName\" + $ADObject.sAMAccountName)
                    Return ("$DomainNetBIOSName\" + $ADObject.sAMAccountName)
                }
                else
                {
                    Write-Verbose ($ADObject.sAMAccountName)
                    Return ($ADObject.sAMAccountName)
                }
            }
        }
        else 
        {
            # if object cannot be found then return the original Sid value
            Return $sid
        }
    }
    End
    {
    }
}

<#
.Synopsis
   Resolves an AD Account Name in the form DOMAIN\ACCOUNT to an object SID.
.DESCRIPTION
   A utility function to resolve an AD Account Name in the form DOMAIN\ACCOUNT to an object SID.
.EXAMPLE
   Resolve-NameToObjectSid -IdentityReference 'BUILTIN\Pre-Windows 2000 Compatible Access'

   Returns the SID for the 'BUILTIN\Pre-Windows 2000 Compatible Access' group as a security identifier ("S-1-5-32-554" in String format).
.INPUTS
   An IdentityReference in the form DOMAIN\ACOUNT format.
.OUTPUTS
   Outputs the object SID associated with the account name.
#>
function Resolve-NameToObjectSid
{
    [CmdletBinding(SupportsShouldProcess = $false, 
        PositionalBinding = $true)]
    [OutputType([Object])]
    Param
    (
        # The IdentityReference to Translate
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false, Position = 0)]
        [String]
        $IdentityReference
    )
    Begin
    {
    }
    Process
    {
        Write-Verbose "Resolving name $IdentityReference..."

        # split the name into Domain and Account Name components
        if ($IdentityReference -match "(?<domain>.*)\x5c(?<account>.*)")
        {
            [string]$DomainName = $Matches.domain
            [string]$AccountName = $Matches.account
        }

        switch ($DomainName)
        {
            { (($null -eq $_) -or ("NT AUTHORITY" -eq $_ )) }
            {
                Write-Verbose " Translating name to Sid using Translate()."  
                try
                {
                    $ntAccount = new-object System.Security.Principal.NTAccount($IdentityReference) 
                    $objectSid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier]) 
                }
                catch
                {
                    Write-Warning -Message ($LocalizedData.TranslateNameError -f $IdentityReference)
                    throw $_
                }

                Return $objectSid
            }
            Default
            {
                # most sids are resolved using Get-AdObject. Ideally would prefer to use Translate([System.Security.Principal.SecurityIdentifier]) but doesn't work very well
                # with anything but the current domain or with certain BUILTIN security principals and don't really want to maintain tables of well-known-sids
                Write-Verbose " Resolving name to objectSid using Get-ADObject."  

                try
                {
                    $DomainNetBIOSName = (Get-ADDomain).NetBIOSName
                }
                catch
                {
                    Write-Warning -Message ($LocalizedData.NetBIOSDomainError)
                    throw $_
                } 

                # build param list to splat to Get-ADObject
                $GetADObjectParams = @{"filter" = ("sAMAccountName -eq " + '"' + $AccountName + '"' + ""); "properties" = "objectSid"; "ErrorAction" = "Stop"}
                if (($DomainName -ne $DomainNetBIOSName) -and ($DomainName -ne "BUILTIN"))
                { 
                    $GetADObjectParams.Add("Server", $DomainName)
                }

                try
                {
                    $ADObject = Get-AdObject @GetADObjectParams
                }
                catch
                {
                    Write-Warning -Message ($LocalizedData.GetADObjectNameError -f $IdentityReference, $AccountName)
                    throw $_
                }
                
                if ($null -ne $ADObject)
                {
                    # return the objectSID
                    Return ($ADObject.objectSID)
                }
                else 
                {
                    # else return $null
                    Return $null
                }  
            }
        }
    }
    End
    {
    }
}

