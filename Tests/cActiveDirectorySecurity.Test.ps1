# Pester test file for module unit testing

Set-StrictMode -Version Latest

$ModulePath = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$ModuleName = 'cActiveDirectorySecurity'

Import-Module (Join-Path $ModulePath "$ModuleName.psm1") -Force

## Disable default ADWS drive warning
$Env:ADPS_LoadDefaultDrive = 0
Import-Module -Name ActiveDirectory -Force

try
{
    InModuleScope $ModuleName {
        Describe "Test the Get-ADObjectRightsGUID function which enumerates Active Directory Schema and Extended Rights GUIDs." {
            Mock -CommandName Get-ADRootDSE -MockWith { New-Object -TypeName PSObject -Property @{"configurationNamingContext" = "CN=Configuration,DC=contoso,DC=com"; "schemaNamingContext" = "CN=Schema,CN=Configuration,DC=contoso,DC=com"; }}
            Context "Retrieve all Schema and Extended Rights GUIDs and their names." {
                Mock -CommandName Get-ADObject -ParameterFilter {$LDAPFilter -eq '(schemaIDGUID=*)'} -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) }
                Mock -CommandName Get-ADObject -ParameterFilter {$LDAPFilter -eq '(objectClass=controlAccessRight)'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) }
                It "Test that all the Active Directory Schema Object and Extended Rights GUID retrieved from the (mocked) contoso.com Domain total 1843 in number." {
                    (Get-ADObjectRightsGUID).count | Should Be 1843
                }
            }
            Context "Retrieve a Schema object matching a specific name filter." {
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=Computer))' } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Computer'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(objectClass=controlAccessRight)(Name=Computer))'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Computer'} } -Verifiable
                It "Test that when a Name filter is provided only the relevant schema object is returned (computer)." {
                    $rtVal = Get-ADObjectRightsGUID -Name 'Computer'
                    $rtVal.Values | Select-Object -First 1 | Should Be 'Computer'
                    Assert-MockCalled -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=Computer))' } -Times 1
                    Assert-MockCalled -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(objectClass=controlAccessRight)(Name=Computer))' } -Times 1
                }
            }
            Context "Retrieve an Extended Right matching a specific name filter." {
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=Personal-Information))' } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Personal-Information'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(objectClass=controlAccessRight)(Name=Personal-Information))'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Personal-Information'} } -Verifiable
                It "Test that when a Name filter is provided only the relevant extended right object is returned (Personal-Information)." {
                    $rtVal = Get-ADObjectRightsGUID -Name 'Personal-Information'
                    $rtVal.Values | Select-Object -First 1 | Should Be 'Personal-Information'
                    Assert-MockCalled -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=Personal-Information))' } -Times 1
                    Assert-MockCalled -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(objectClass=controlAccessRight)(Name=Personal-Information))' } -Times 1
                }
            }
            Context "Retrieve an Extended Right matching a specific GUID filter." {
                $PersonalInformationGUID = [GUID]"77B5B886-944A-11d1-AEBD-0000F80367C1"
                Mock -CommandName Get-ADObject -ParameterFilter { $Filter -like "*schemaIDGUID*" } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.schemaIDGUID -eq ($PersonalInformationGUID.ToString())} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $Filter -like "*rightsGUID*" } -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.rightsGUID -eq ($PersonalInformationGUID.ToString())} } -Verifiable
                It "Test that when a GUID filter is provided only the relevant extended right object is returned (Personal-Information)." {
                    $rtVal = Get-ADObjectRightsGUID -GUID $PersonalInformationGUID
                    $rtVal.Values | Select-Object -First 1 | Should Be 'Personal-Information'
                    Assert-MockCalled -CommandName Get-ADObject { $Filter -like "*schemaIDGUID*" }  -Times 1
                    Assert-MockCalled -CommandName Get-ADObject -ParameterFilter { $Filter -like "*rightsGUID*" } -Times 1
                }
            }
            Context "Retrieve an Schema object matching a specific GUID filter." {
                $ComputerGUID = [GUID]"bf967a86-0de6-11d0-a285-00aa003049e2"
                Mock -CommandName Get-ADObject -ParameterFilter { $Filter -like "*schemaIDGUID*" } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.schemaIDGUID -eq ($ComputerGUID.ToString())} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $Filter -like "*rightsGUID*" } -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.rightsGUID -eq ($ComputerGUID.ToString())} } -Verifiable
                It "Test that when a GUID filter is provided only the relevant extended right object is returned (Computer)." {
                    $rtVal = Get-ADObjectRightsGUID -GUID $ComputerGUID
                    $rtVal.Values | Select-Object -First 1 | Should Be 'Computer'
                    Assert-MockCalled -CommandName Get-ADObject { $Filter -like "*schemaIDGUID*" }  -Times 1
                    Assert-MockCalled -CommandName Get-ADObject -ParameterFilter { $Filter -like "*rightsGUID*" } -Times 1
                }
            }
            Context "The Schema Object / Extended Right specified cannot be found." {
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=Computers))' } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Computers'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(objectClass=controlAccessRight)(Name=Computers))'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Computers'} } -Verifiable
                It "Tests that a null value is returned where the specified Schema Object / Extended Right doesn't exist." {
                    Get-ADObjectRightsGUID -Name 'Computers' | Should Be $null
                    Assert-MockCalled -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=Computers))' } -Times 1
                    Assert-MockCalled -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(objectClass=controlAccessRight)(Name=Computers))' } -Times 1
                }
            }
            Context "Retrieve the 'All' Schema Object / Extended Right by Name, which needs to be handled specifically." {
                It "Test that a value of 'All' is passed to the Name filter only the relevant object is returned (All)." {
                    $rtVal = Get-ADObjectRightsGUID -Name 'All'
                    $rtVal.Values | Select-Object -First 1 | Should Be 'All'
                }
            }
            Context "Retrieve the 'All' Schema Object / Extended Right by GUID, which needs to be handled specifically." {
                $AllGUID = [GUID]'00000000-0000-0000-0000-000000000000'
                It "Test that a GUID of '00000000-0000-0000-0000-000000000000' is passed to the GUID filter only the relevant object is returned (All)." {
                    $rtVal = Get-ADObjectRightsGUID -GUID $AllGUID
                    $rtVal.Values | Select-Object -First 1 | Should Be 'All'
                }
            }
        }
        Describe "Test some basic error handling of the Get-ADObjectAcl function." {
            Mock -CommandName Get-ADDomain -MockWith { New-Object -TypeName PSObject -Property @{"NetBIOSName" = "CONTOSO"} }
            Context "Test Identity parameter passed as string and where object cannot be found." {
                Mock -CommandName Write-Warning -MockWith { } -ParameterFilter {$Message -like "An error occurred locating an object with the identity specified ('CN=JoeB,CN=Users,DC=contoso,DC=com').*"  } -Verifiable
                Mock -CommandName Write-Error -MockWith { } -Verifiable
                Mock -CommandName Set-Location -MockWith { }
                Mock -CommandName  Get-ADObjectRightsGUID -MockWith { }
                Mock Get-ADObject -MockWith { throw "Get-ADObject : Cannot find an object with identity: 'CN=JoeB,CN=Users,DC=contoso,DC=com' under: 'DC=contoso,DC=com'."}
                It "Generates a warning and error message when the specified identity (in string format) cannot be found." {
                    Get-ADObjectAcl -Identity 'CN=JoeB,CN=Users,DC=contoso,DC=com' | Should Be $null
                    Assert-MockCalled -CommandName Write-Warning -Times 1
                    Assert-MockCalled -CommandName Write-Error -Times 1
                }
            }
            Context "Test Identity parameter set to an object that doesn't include either of the mandatory properties of either DistinguishedName or objectGUID." {
                $Identity = New-Object -TypeName PSObject -Property @{sAMAccountName = "Test"}
                Mock -CommandName Write-Warning -MockWith { } -Verifiable
                Mock -CommandName Write-Error -MockWith { } -Verifiable
                Mock -CommandName Set-Location -MockWith { }
                Mock -CommandName  Get-ADObjectRightsGUID -MockWith { }
                It "Generates a warning and error message when the Identity Object passed doesn't include either a DistinguishedName or ObjectGUID property." {
                    Get-ADObjectAcl -Identity $Identity | Should Be $null
                    Assert-MockCalled -CommandName Write-Warning -Times 1
                    Assert-MockCalled -CommandName Write-Error -Times 1
                }
            }
        }
        Describe "Simulate calls to the Get-ADObjectAcl functions with mock data from the root of the default (CONTOSO) Domain." {
            Mock -CommandName Get-ADRootDSE -MockWith { New-Object -TypeName PSObject -Property @{"configurationNamingContext" = "CN=Configuration,DC=contoso,DC=com"; "schemaNamingContext" = "CN=Schema,CN=Configuration,DC=contoso,DC=com"; }}
            Mock -CommandName Get-ADDomain -MockWith { New-Object -TypeName PSObject -Property @{"NetBIOSName" = "CONTOSO"} }
            $Identity = New-Object -TypeName PSObject -Property @{"Name" = "CONTOSO"; "DistinguishedName" = "DC=contoso,DC=com" ; "DNSRoot" = "contoso.com"}
            Mock -CommandName Get-ADObject -ParameterFilter {$LDAPFilter -eq '(schemaIDGUID=*)'} -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) }
            Mock -CommandName Get-ADObject -ParameterFilter {$LDAPFilter -eq '(objectClass=controlAccessRight)'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) }
            Mock -CommandName Set-Location -MockWith { }
            Mock -CommandName Resolve-ObjectSidToName -MockWith { Return $Sid }
            Context "Gather permissions from the root of the default (CONTOSO) Domain." {
                Mock -CommandName Get-Acl -MockWith { 
                    $ContosoAcl = (Get-Content -Path "$ModulePath\Tests\MockPermissions.json" -Raw | ConvertFrom-Json).ContosoDomainPermissions 
                    $permissions = $ContosoAcl | Select-Object -Property @(
                        "ActiveDirectoryRights"
                        "InheritanceType"
                        @{n = "ObjectType"; e = {[System.GUID]$_.ObjectType}}
                        @{n = "InheritedObjectType"; e = {[System.GUID]$_.InheritedObjectType}}
                        "ObjectFlags"
                        "AccessControlType"
                        "IdentityReference"
                        "IsInherited"
                        "InheritanceFlags"
                        "PropagationFlags"
                    )
                    Return New-Object -TypeName PSObject -Property @{"Access" = $permissions}
                }
                It "Tests that all ACEs (53) are returned." {
                    (Get-ADObjectAcl -Identity $Identity).count | Should Be 53
                }
                It "Tests that filtering with the IdentityReference parameter retrieves only pertinent objects (1)." {
                    $rtVal = Get-ADObjectAcl -Identity $Identity -IdentityReference "CONTOSO\Domain Admins"
                    $rtVal | Select-Object -ExpandProperty IdentityReference | Should Be "CONTOSO\Domain Admins"
                }
                It "Tests that filtering with IsInherited flag set to false retrieves only pertinent objects (53). At the root of the domain no permissions are inherited." {
                    $rtVal = Get-ADObjectAcl -Identity $Identity -IsInherited $false
                    $rtVal.count | Should Be 53
                }
                It "Tests that filtering with the IsInherited parameter set to true retrieves only pertinent objects (0). At the root of the domain no permissions are inherited." {
                    $rtVal = Get-ADObjectAcl -Identity $Identity -IsInherited $true
                    $rtVal.count | Should Be 0
                }
                It "Tests that filtering with the ActiveDirectoryRights parameter retrieves only pertinent objects (17)." {
                    $rtVal = Get-ADObjectAcl -Identity $Identity -ActiveDirectoryRights ReadProperty
                    $rtVal.count | Should Be 17
                }
                It "Tests that filtering with multiple ActiveDirectoryRights retrieves only pertinent objects (3)." {
                    $rtVal = Get-ADObjectAcl -Identity $Identity -ActiveDirectoryRights ReadProperty, WriteProperty
                    $rtVal.count | Should Be 3
                    $rtVal | Select-Object -ExpandProperty IdentityReference -First 1 | Should Be "NT Authority\SELF"
                    $rtVal | Select-Object -ExpandProperty IdentityReference -Last 1 | Should Be "CONTOSO\Enterprise Key Admins"
                }
                It "Tests that filtering on InheritanceType retrieves only pertinent objects (4)." {
                    $rtVal = Get-ADObjectAcl -Identity $Identity -InheritanceType Descendents
                    $rtVal.count | Should Be 20
                    $rtVal | Select-Object -ExpandProperty IdentityReference -First 1 | Should Be "CREATOR OWNER"
                    $rtVal | Select-Object -ExpandProperty IdentityReference -Last 1 | Should Be "BUILTIN\Pre-Windows 2000 Compatible Access"
                }
                It "Tests that filtering on InheritedObjectTypeName retrieves only pertinent objects (4)." {
                    $rtVal = Get-ADObjectAcl -Identity $Identity -InheritedObjectTypeName Computer
                    $rtVal.count | Should Be 4
                    $rtVal | ForEach-Object { $_ | Select-Object -ExpandProperty InheritedObjectTypeName | Should Be "Computer" }
                }
                It "Tests that filtering on ObjectTypeName retrieves only pertinent objects (2)." {
                    $rtVal = Get-ADObjectAcl -Identity $Identity -ObjectTypeName DS-Validated-Write-Computer
                    $rtVal.count | Should Be 2
                    $rtVal | ForEach-Object { $_ | Select-Object -ExpandProperty ObjectTypeName | Should Be "DS-Validated-Write-Computer" }
                }
            }
        }
        Describe "Simulate calls to the Get-ADObjectAcl functions with mock data from the Domain Controllers Organizational Unit of the default (CONTOSO) Domain." {
            Mock -CommandName Get-ADRootDSE -MockWith { New-Object -TypeName PSObject -Property @{"configurationNamingContext" = "CN=Configuration,DC=contoso,DC=com"; "schemaNamingContext" = "CN=Schema,CN=Configuration,DC=contoso,DC=com"; }}
            Mock -CommandName Get-ADDomain -MockWith { New-Object -TypeName PSObject -Property @{"NetBIOSName" = "CONTOSO"} }
            $Identity = New-Object -TypeName PSObject -Property @{"Name" = "Domain Controllers"; "DistinguishedName" = "OU=Domain Controllers,DC=contoso,DC=com"}
            Mock -CommandName Get-ADObject -ParameterFilter {$LDAPFilter -eq '(schemaIDGUID=*)'} -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) }
            Mock -CommandName Get-ADObject -ParameterFilter {$LDAPFilter -eq '(objectClass=controlAccessRight)'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) }
            Mock -CommandName Set-Location -MockWith { }
            Mock -CommandName Resolve-ObjectSidToName -MockWith { Return $Sid }
            Context "Gather all permissions from the Domain Controllers Organizational Units of the default (CONTOSO) Domain." {
                Mock -CommandName Get-Acl -MockWith { 
                    $ContosoAcl = (Get-Content -Path "$ModulePath\Tests\MockPermissions.json" -Raw | ConvertFrom-Json).ContosoDomainControllersPermissions 
                    $permissions = $ContosoAcl | Select-Object -Property @(
                        "ActiveDirectoryRights"
                        "InheritanceType"
                        @{n = "ObjectType"; e = {[System.GUID]$_.ObjectType}}
                        @{n = "InheritedObjectType"; e = {[System.GUID]$_.InheritedObjectType}}
                        "ObjectFlags"
                        "AccessControlType"
                        "IdentityReference"
                        "IsInherited"
                        "InheritanceFlags"
                        "PropagationFlags"
                    )
                    Return New-Object -TypeName PSObject -Property @{"Access" = $permissions}
                }
                It "Tests that all ACEs (30) are returned." {
                    (Get-ADObjectAcl -Identity $Identity).count | Should Be 30
                }
                It "Tests that filtering with IsInherited flag set to false retrieves only pertinent objects (4)." {
                    $rtVal = Get-ADObjectAcl -Identity $Identity -IsInherited $false
                    $rtVal.count | Should Be 4
                }
                It "Tests that filtering with the IsInherited parameter set to true retrieves only pertinent objects (26)." {
                    $rtVal = Get-ADObjectAcl -Identity $Identity -IsInherited $true
                    $rtVal.count | Should Be 26
                }
            }
        }
        Describe "Test some basic error handling of the Add-ADObjectAce function." {
            Mock -CommandName Get-ADRootDSE -MockWith { New-Object -TypeName PSObject -Property @{"configurationNamingContext" = "CN=Configuration,DC=contoso,DC=com"; "schemaNamingContext" = "CN=Schema,CN=Configuration,DC=contoso,DC=com"; }}
            Mock -CommandName Get-ADDomain -MockWith { New-Object -TypeName PSObject -Property @{"NetBIOSName" = "CONTOSO"} }
            Mock -CommandName Set-Location -MockWith { }
            Context "The specified Identity cannot be found." {
                Mock Get-ADObject -MockWith { throw "Get-ADObject : Cannot find an object with identity: 'CN=JoeB,CN=Users,DC=contoso,DC=com' under: 'DC=contoso,DC=com'."}
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=Computers))' } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Computers'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(objectClass=controlAccessRight)(Name=Computers))'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Computers'} } -Verifiable
                Mock -CommandName Write-Warning -MockWith { } -ParameterFilter {$Message -like "An error occurred locating an object with the identity specified ('CN=JoeB,CN=Users,DC=contoso,DC=com').*"  } -Verifiable
                Mock -CommandName Write-Error -MockWith {} -Verifiable
                It "Generates a warning and error message when the specified Identity cannot be found." {
                    Add-ADObjectAce -Identity 'CN=JoeB,CN=Users,DC=contoso,DC=com' -IdentityReference "CONTOSO\JaneD" -ActiveDirectoryRights ReadProperty, WriteProperty, ExtendedRight -ObjectTypeName 'Private-Information'  | Should Be $null
                    Assert-MockCalled -CommandName Write-Warning -Times 1
                    Assert-MockCalled -CommandName Write-Error -Times 1
                }
            }
            Context "The specified Identity Reference cannot be translated to a Sid." {
                $Identity = New-Object -TypeName PSObject -Property @{"Name" = "Domain Controllers"; "DistinguishedName" = "OU=Domain Controllers,DC=contoso,DC=com"}
                Mock -CommandName Resolve-NameToObjectSid -ParameterFilter {$IdentityReference -eq "CONTOSO\Domain Admins"} -MockWith { Return $null }
                Mock -CommandName Write-Warning -MockWith { } -ParameterFilter {$Message -eq "An error occurred translating the Identity Reference ('CONTOSO\Domain Admins') to a Sid value. Processing cannot continue."} -Verifiable
                It "Generates a warning message when the specified Identity Reference cannot be translated into an object Sid value." {
                    Add-ADObjectAce -Identity $Identity -IdentityReference "CONTOSO\Domain Admins" -ActiveDirectoryRights CreateChild, DeleteChild -ObjectTypeName 'Computers' -InheritedObjectTypeName 'All'  | Should Be $null
                    Assert-MockCalled -CommandName Write-Warning -Times 1
                }
            }
            Context "The specified ObjectTypeName cannot be found." {
                $Identity = New-Object -TypeName PSObject -Property @{"Name" = "Domain Controllers"; "DistinguishedName" = "OU=Domain Controllers,DC=contoso,DC=com"}
                Mock -CommandName Resolve-NameToObjectSid -ParameterFilter {$IdentityReference -eq "CONTOSO\Domain Admins"} -MockWith { Return (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-21-2295585024-2604479722-1786026388-516")) }
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=Computers))' } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Computers'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(objectClass=controlAccessRight)(Name=Computers))'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Computers'} } -Verifiable
                Mock -CommandName Write-Warning -MockWith { } -ParameterFilter {$Message -eq "An error occurred locating the ObjectTypeName with the name specified ('Computers')."} -Verifiable
                It "Generates a warning and error message when the specified ObjectTypeName cannot be found and returns a null value." {
                    Add-ADObjectAce -Identity $Identity -IdentityReference "CONTOSO\Domain Admins" -ActiveDirectoryRights CreateChild, DeleteChild -ObjectTypeName 'Computers' -InheritedObjectTypeName 'All'  | Should Be $null
                    Assert-MockCalled -CommandName Write-Warning -Times 1
                }
            }
            Context "The specified InheritedObjectTypeName cannot be found." {
                $Identity = New-Object -TypeName PSObject -Property @{"Name" = "Computers"; "DistinguishedName" = "CN=Computers,DC=contoso,DC=com"}
                Mock -CommandName Resolve-NameToObjectSid -ParameterFilter {$IdentityReference -eq "CONTOSO\Domain Admins"} -MockWith { Return (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-21-2295585024-2604479722-1786026388-516")) }
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=ms-TPM-Tpm-Information-For-Computer))' } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'ms-TPM-Tpm-Information-For-Computer'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=Computers))' } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Computers'} } -Verifiable
                Mock -CommandName Write-Warning -MockWith { } -ParameterFilter {$Message -eq "An error occurred locating the InheritedObjectTypeName with the name specified ('Computers')."} -Verifiable
                It "Generates a warning when the specified ObjectTypeName cannot be found and returns a null value." {
                    Add-ADObjectAce -Identity $Identity -IdentityReference "CONTOSO\Domain Admins" -ActiveDirectoryRights WriteProperty -ObjectTypeName 'ms-TPM-Tpm-Information-For-Computer' -InheritedObjectTypeName 'Computers'  | Should Be $null
                    Assert-MockCalled -CommandName Write-Warning -Times 1
                }
            }
        }
        Describe "Use the Add-ADObjectAce function to generate some Access Control Entries and ensure they compare to their equivalents." {
            # https://msdn.microsoft.com/en-us/library/system.directoryservices.activedirectoryaccessrule(v=vs.110).aspx
            Mock -CommandName Get-ADRootDSE -MockWith { New-Object -TypeName PSObject -Property @{"configurationNamingContext" = "CN=Configuration,DC=contoso,DC=com"; "schemaNamingContext" = "CN=Schema,CN=Configuration,DC=contoso,DC=com"; }}
            Mock -CommandName Get-ADDomain -MockWith { New-Object -TypeName PSObject -Property @{"NetBIOSName" = "CONTOSO"} }
            Mock -CommandName Get-ADObject -ParameterFilter {$LDAPFilter -eq '(schemaIDGUID=*)'} -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) }
            Mock -CommandName Get-ADObject -ParameterFilter {$LDAPFilter -eq '(objectClass=controlAccessRight)'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) }
            Mock -CommandName Set-Location -MockWith { }
            Mock -CommandName Resolve-ObjectSidToName -MockWith { Return $Sid }
            Mock -CommandName Get-Acl -MockWith { 
                $ContosoAcl = (Get-Content -Path "$ModulePath\Tests\MockPermissions.json" -Raw | ConvertFrom-Json).ContosoDomainPermissions 
                $permissions = $ContosoAcl | Select-Object -Property @(
                    "ActiveDirectoryRights"
                    "InheritanceType"
                    @{n = "ObjectType"; e = {[System.GUID]$_.ObjectType}}
                    @{n = "InheritedObjectType"; e = {[System.GUID]$_.InheritedObjectType}}
                    "ObjectFlags"
                    "AccessControlType"
                    "IdentityReference"
                    "IsInherited"
                    "InheritanceFlags"
                    "PropagationFlags"
                )
                Return New-Object -TypeName PSObject -Property @{"Access" = $permissions}
            }
            $props = @("AccessControlType", "ActiveDirectoryRights", "DistinguishedName", "IdentityReference", "InheritanceFlags", "InheritanceType", "InheritedObjectType", "InheritedObjectTypeName", "IsInherited", "ObjectFlags", "ObjectType", "ObjectTypeName", "PropagationFlags", "IdentityReferenceDomain", "IdentityReferenceName")
            $Identity = New-Object -TypeName PSObject -Property @{"Name" = "Domain Controllers"; "DistinguishedName" = "OU=Domain Controllers,DC=contoso,DC=com"}
            Context "Retrieve a specific ACE from the root of the default (CONTOSO) Domain and compare it to an equivalent ACE generated by Add-ADObjectAce (IdentityReference, ActiveDirectoryRights, AccessControlType) (-Whatif)." {
                # https://msdn.microsoft.com/en-us/library/99s25ayd(v=vs.110).aspx
                Mock -CommandName Resolve-NameToObjectSid -ParameterFilter {$IdentityReference -eq "CONTOSO\Domain Admins"} -MockWith { Return (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-21-2295585024-2604479722-1786026388-512")) }
                $Ace1 = Get-ADObjectAcl -Identity $Identity -IdentityReference "CONTOSO\Domain Admins" -ActiveDirectoryRights CreateChild, Self, WriteProperty, ExtendedRight, GenericRead, WriteDacl, WriteOwner -AccessControlType Allow
                $Ace2 = Add-ADObjectAce -Identity $Identity -IdentityReference "CONTOSO\Domain Admins" -ActiveDirectoryRights CreateChild, Self, WriteProperty, ExtendedRight, GenericRead, WriteDacl, WriteOwner -AccessControlType Allow -Whatif
                forEach ($prop in $props)
                {
                    It "Compares the $prop property of the two Access Control Entries." {
                        Compare-Object -ReferenceObject $Ace1 -DifferenceObject $Ace2 -Property $prop | Should Be $null
                    }
                }
            }
            Context "Retrieve a specific ACE from the root of the default (CONTOSO) Domain and compare it to an equivalent ACE generated by Add-ADObjectAce (IdentityReference, ActiveDirectoryRights, AccessControlType, ActiveDirectorySecurityInheritance) (-Whatif)." {
                # https://msdn.microsoft.com/en-us/library/xh02bekw(v=vs.110).aspx
                Mock -CommandName Resolve-NameToObjectSid -ParameterFilter {$IdentityReference -eq "CONTOSO\Enterprise Admins"} -MockWith { Return (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-21-2295585024-2604479722-1786026388-519")) }
                $Ace1 = Get-ADObjectAcl -Identity $Identity -IdentityReference "CONTOSO\Enterprise Admins" -ActiveDirectoryRights GenericAll -AccessControlType Allow -InheritanceType All
                $Ace2 = Add-ADObjectAce -Identity $Identity -IdentityReference "CONTOSO\Enterprise Admins" -ActiveDirectoryRights GenericAll -AccessControlType Allow -InheritanceType All -WhatIf
                forEach ($prop in $props)
                {
                    It "Compares the $prop property of the two Access Control Entries." {
                        Compare-Object -ReferenceObject $Ace1 -DifferenceObject $Ace2 -Property $prop | Should Be $null
                    }
                }
            }
            Context "Retrieve a specific ACE from the root of the default (CONTOSO) Domain and compare it to an equivalent ACE generated by Add-ADObjectAce (IdentityReference, ActiveDirectoryRights, AccessControlType, ActiveDirectorySecurityInheritance, Guid) (-Whatif)." {
                # https://msdn.microsoft.com/en-us/library/4b75624d(v=vs.110).aspx
                Mock -CommandName Resolve-NameToObjectSid -ParameterFilter {$IdentityReference -eq "BUILTIN\Pre-Windows 2000 Compatible Access"} -MockWith { Return (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-554")) }
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=Group))' } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Group'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(objectClass=controlAccessRight)(Name=Group))'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Group'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $Filter -like "*schemaIDGUID*"} -MockWith { (Get-Content -Path "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.schemaIDGUID -eq 'bf967a9c-0de6-11d0-a285-00aa003049e2'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $Filter -like "*rightsGUID*"} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.rightsGUID -eq 'bf967a9c-0de6-11d0-a285-00aa003049e2'} } -Verifiable
                $Ace1 = Get-ADObjectAcl -Identity $Identity -IdentityReference "BUILTIN\Pre-Windows 2000 Compatible Access" -ActiveDirectoryRights GenericRead -AccessControlType Allow -InheritanceType Descendents -InheritedObjectTypeName "Group" 
                $Ace2 = Add-ADObjectAce -Identity $Identity -IdentityReference "BUILTIN\Pre-Windows 2000 Compatible Access" -ActiveDirectoryRights GenericRead -AccessControlType Allow -InheritanceType Descendents -InheritedObjectTypeName "Group" -WhatIf
                forEach ($prop in $props)
                {
                    It "Compares the $prop property of the two Access Control Entries." {
                        Compare-Object -ReferenceObject $Ace1 -DifferenceObject $Ace2 -Property $prop | Should Be $null
                    }
                }
            }
            Context "Retrieve a specific ACE from the root of the default (CONTOSO) Domain and compare it to an equivalent ACE generated by Add-ADObjectAce (IdentityReference, ActiveDirectoryRights, AccessControlType, Guid) (-Whatif)." {
                # https://msdn.microsoft.com/en-us/library/sskw937h(v=vs.110).aspx
                Mock -CommandName Resolve-NameToObjectSid -ParameterFilter {$IdentityReference -eq "CONTOSO\Domain Controllers"} -MockWith { Return (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-21-2295585024-2604479722-1786026388-516")) }
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=DS-Replication-Get-Changes-All))' } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'DS-Replication-Get-Changes-All'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(objectClass=controlAccessRight)(Name=DS-Replication-Get-Changes-All))'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'DS-Replication-Get-Changes-All'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $Filter -like "*schemaIDGUID*"} -MockWith { (Get-Content -Path "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.schemaIDGUID -eq '1131f6ad-9c07-11d1-f79f-00c04fc2dcd2'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $Filter -like "*rightsGUID*"} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.rightsGUID -eq '1131f6ad-9c07-11d1-f79f-00c04fc2dcd2'} } -Verifiable
                $Ace1 = Get-ADObjectAcl -Identity $Identity -IdentityReference "CONTOSO\Domain Controllers" -ActiveDirectoryRights ExtendedRight -AccessControlType Allow -ObjectTypeName "DS-Replication-Get-Changes-All" 
                $Ace2 = Add-ADObjectAce -Identity $Identity -IdentityReference "CONTOSO\Domain Controllers" -ActiveDirectoryRights ExtendedRight -AccessControlType Allow -ObjectTypeName "DS-Replication-Get-Changes-All" -WhatIf
                forEach ($prop in $props)
                {
                    It "Compares the $prop property of the two Access Control Entries." {
                        Compare-Object -ReferenceObject $Ace1 -DifferenceObject $Ace2 -Property $prop | Should Be $null
                    }
                }
            }
            Context "Retrieve a specific ACE from the root of the default (CONTOSO) Domain and compare it to an equivalent ACE generated by Add-ADObjectAce (IdentityReference, ActiveDirectoryRights, AccessControlType, Guid, ActiveDirectorySecurityInheritance) (-Whatif)." {
                # https://msdn.microsoft.com/en-us/library/cawwkf0x(v=vs.110).aspx
                Mock -CommandName Resolve-NameToObjectSid -ParameterFilter {$IdentityReference -eq "CONTOSO\Key Admins"} -MockWith { Return (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-21-2295585024-2604479722-1786026388-526")) }
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=ms-DS-Key-Credential-Link))' } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'ms-DS-Key-Credential-Link'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(objectClass=controlAccessRight)(Name=ms-DS-Key-Credential-Link))'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'ms-DS-Key-Credential-Link'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $Filter -like "*schemaIDGUID*"} -MockWith { (Get-Content -Path "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.schemaIDGUID -eq '5b47d60f-6090-40b2-9f37-2a4de88f3063'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $Filter -like "*rightsGUID*"} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.rightsGUID -eq '5b47d60f-6090-40b2-9f37-2a4de88f3063'} } -Verifiable
                $Ace1 = Get-ADObjectAcl -Identity $Identity -IdentityReference "CONTOSO\Key Admins" -ActiveDirectoryRights ReadProperty, WriteProperty -AccessControlType Allow -ObjectTypeName "ms-DS-Key-Credential-Link" -InheritanceType All
                $Ace2 = Add-ADObjectAce -Identity $Identity -IdentityReference "CONTOSO\Key Admins" -ActiveDirectoryRights ReadProperty, WriteProperty -AccessControlType Allow -ObjectTypeName "ms-DS-Key-Credential-Link" -InheritanceType All -WhatIf
                forEach ($prop in $props)
                {
                    It "Compares the $prop property of the two Access Control Entries." {
                        Compare-Object -ReferenceObject $Ace1 -DifferenceObject $Ace2 -Property $prop | Should Be $null
                    }
                }
            }
            Context "Retrieve a specific ACE from the root of the default (CONTOSO) Domain and compare it to an equivalent ACE generated by Add-ADObjectAce (IdentityReference, ActiveDirectoryRights, AccessControlType, Guid, ActiveDirectorySecurityInheritance, Guid) (-Whatif)." {
                # https://msdn.microsoft.com/en-us/library/w72e8e69(v=vs.110).aspx
                Mock -CommandName Resolve-NameToObjectSid -ParameterFilter {$IdentityReference -eq "BUILTIN\Pre-Windows 2000 Compatible Access"} -MockWith { Return (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-554")) }
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=User))' } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'User'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(objectClass=controlAccessRight)(Name=General-Information))'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'General-Information'} } -Verifiable
                $objectTypeGUID = [GUID]'59ba2f42-79a2-11d0-9020-00c04fc2d3cf' # General-Information
                $inheritedObjectTypeGUID = [GUID]'bf967aba-0de6-11d0-a285-00aa003049e2' # user
                Mock -CommandName Get-ADObjectRightsGUID -ParameterFilter { $GUID -eq $objectTypeGUID } -MockWith { $accessRightsObject = (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.rightsGUID -eq $objectTypeGUID.ToString()}; Return @{[GUID]$accessRightsObject.rightsGUID = $accessRightsObject.Name} } -Verifiable
                Mock -CommandName Get-ADObjectRightsGUID -ParameterFilter { $GUID -eq $inheritedObjectTypeGUID } -MockWith { $schemaObject = (Get-Content -Path "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.schemaIDGUID -eq $inheritedObjectTypeGUID.ToString()}; Return @{[GUID]$schemaObject.schemaIDGUID = $schemaObject.Name} } -Verifiable
                $Ace1 = Get-ADObjectAcl -Identity $Identity -IdentityReference "BUILTIN\Pre-Windows 2000 Compatible Access" -ActiveDirectoryRights ReadProperty -AccessControlType Allow -ObjectTypeName "General-Information" -InheritanceType Descendents -InheritedObjectTypeName "User"
                $Ace2 = Add-ADObjectAce -Identity $Identity -IdentityReference "BUILTIN\Pre-Windows 2000 Compatible Access" -ActiveDirectoryRights ReadProperty -AccessControlType Allow -ObjectTypeName "General-Information" -InheritanceType Descendents -InheritedObjectTypeName "User" -WhatIf
                forEach ($prop in $props)
                {
                    It "Compares the $prop property of the two Access Control Entries." {
                        Compare-Object -ReferenceObject $Ace1 -DifferenceObject $Ace2 -Property $prop | Should Be $null
                    }
                }
            }
        }
        Describe "Use the Remove-ADObjectAce function to identify some Access Control Entries for removal and ensure they compare to their equivalents." {
            Mock -CommandName Get-ADRootDSE -MockWith { New-Object -TypeName PSObject -Property @{"configurationNamingContext" = "CN=Configuration,DC=contoso,DC=com"; "schemaNamingContext" = "CN=Schema,CN=Configuration,DC=contoso,DC=com"; }}
            Mock -CommandName Get-ADDomain -MockWith { New-Object -TypeName PSObject -Property @{"NetBIOSName" = "CONTOSO"} }
            Mock -CommandName Get-ADObject -ParameterFilter {$LDAPFilter -eq '(schemaIDGUID=*)'} -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) }
            Mock -CommandName Get-ADObject -ParameterFilter {$LDAPFilter -eq '(objectClass=controlAccessRight)'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) }
            Mock -CommandName Set-Location -MockWith { }
            Mock -CommandName Pop-Location -MockWith { }
            Mock -CommandName Resolve-ObjectSidToName -MockWith { Return $Sid }
            Mock -CommandName Get-Acl -MockWith { 
                $ContosoAcl = (Get-Content -Path "$ModulePath\Tests\MockPermissions.json" -Raw | ConvertFrom-Json).ContosoDomainGBGroupPermissions 
                $permissions = $ContosoAcl | Select-Object -Property @(
                    "ActiveDirectoryRights"
                    "InheritanceType"
                    @{n = "ObjectType"; e = {[System.GUID]$_.ObjectType}}
                    @{n = "InheritedObjectType"; e = {[System.GUID]$_.InheritedObjectType}}
                    "ObjectFlags"
                    "AccessControlType"
                    "IdentityReference"
                    "IsInherited"
                    "InheritanceFlags"
                    "PropagationFlags"
                )
                Return New-Object -TypeName PSObject -Property @{"Access" = $permissions}
            }
            $props = @("AccessControlType", "ActiveDirectoryRights", "DistinguishedName", "IdentityReference", "InheritanceFlags", "InheritanceType", "InheritedObjectType", "InheritedObjectTypeName", "IsInherited", "ObjectFlags", "ObjectType", "ObjectTypeName", "PropagationFlags", "IdentityReferenceDomain", "IdentityReferenceName")
            $Identity = New-Object -TypeName PSObject -Property @{"Name" = "Groups"; "DistinguishedName" = "OU=Groups,OU=GB,DC=contoso,DC=com"}
            Context "Retrieve a specific ACE from the 'OU=Groups,OU=GB,DC=contoso,DC=com' OU and compare it to an equivalent ACE identified by Remove-ADObjectAce (-Whatif)." {
                Mock -CommandName Resolve-NameToObjectSid -ParameterFilter {$IdentityReference -eq "CONTOSO\Joe.Bloggs"} -MockWith { Return (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-21-2295585024-2604479722-1786026388-1112")) }
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=Group))' } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Group'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(objectClass=controlAccessRight)(Name=Group))'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Group'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $Filter -like "*schemaIDGUID*"} -MockWith { (Get-Content -Path "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.schemaIDGUID -eq 'bf967a9c-0de6-11d0-a285-00aa003049e2'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $Filter -like "*rightsGUID*"} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.rightsGUID -eq 'bf967a9c-0de6-11d0-a285-00aa003049e2'} } -Verifiable
                $Ace1 = Get-ADObjectAcl -Identity $Identity -IdentityReference "CONTOSO\Joe.Bloggs" -ActiveDirectoryRights GenericAll -AccessControlType Allow -InheritedObjectTypeName Group -InheritanceType Descendents
                $Ace2 = Remove-ADObjectAce -Identity $Identity -IdentityReference "CONTOSO\Joe.Bloggs" -ActiveDirectoryRights GenericAll -AccessControlType Allow -InheritedObjectTypeName Group -InheritanceType Descendents -Whatif
                forEach ($prop in $props)
                {
                    It "Compares the $prop property of the two Access Control Entries." {
                        Compare-Object -ReferenceObject $Ace1 -DifferenceObject $Ace2 -Property $prop | Should Be $null
                    }
                }
            }
            Context "Combine use of Get-ADObjectAcl and Remove-ADObjectAce to remove all ACEs for a particular security principal." {
                Mock -CommandName Resolve-NameToObjectSid -ParameterFilter {$IdentityReference -eq "CONTOSO\Joe.Bloggs"} -MockWith { Return (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-21-2295585024-2604479722-1786026388-1112")) }
                Mock -CommandName Get-Location -ParameterFilter {$StackName -eq "cActiveDirectorySecurity"} -MockWith { Return (New-Object -TypeName PSObject -Property @{"Path" = "CONTOSO:"}) }
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(schemaIDGUID=*)(Name=Group))' } -MockWith { (Get-Content "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Group'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(&(objectClass=controlAccessRight)(Name=Group))'} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.Name -eq 'Group'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $Filter -like "*schemaIDGUID*"} -MockWith { (Get-Content -Path "$ModulePath\Tests\schemaObjects.json" -Raw | ConvertFrom-Json) | Where-Object {$_.schemaIDGUID -eq 'bf967a9c-0de6-11d0-a285-00aa003049e2'} } -Verifiable
                Mock -CommandName Get-ADObject -ParameterFilter { $Filter -like "*rightsGUID*"} -MockWith { (Get-Content -Path "$ModulePath\Tests\accessRights.json" -Raw | ConvertFrom-Json) | Where-Object {$_.rightsGUID -eq 'bf967a9c-0de6-11d0-a285-00aa003049e2'} } -Verifiable
                Mock -CommandName Get-ADObject -MockWith { New-Object -TypeName PSObject -Property @{"Name" = "Groups"; "DistinguishedName" = "OU=Groups,OU=GB,DC=contoso,DC=com" } }
                $Ace1 = Get-ADObjectAcl -Identity $Identity -IdentityReference "CONTOSO\Joe.Bloggs"
                $Ace2 = Get-ADObjectAcl -Identity $Identity -IdentityReference "CONTOSO\Joe.Bloggs" | Remove-ADObjectAce -Whatif
                for ($i = 0; $i -lt $Ace1.count; $i++) 
                {
                    forEach ($prop in $props)
                    {
                        It "Compares the $prop property of the two Access Control Entries." {
                            Compare-Object -ReferenceObject $Ace1[$i] -DifferenceObject $Ace2[$i] -Property $prop | Should Be $null
                        }
                    }     
                }
                
            }
        }
    } 
}
catch 
{
    throw $_
}

