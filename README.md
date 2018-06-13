# Project Title

The cActiveDirectorySecurity module contains PowerShell Functions which are designed to report on and manipulate Access Control Lists on Active Directory Objects in an intuitive manner. One of the key benefits of the module is the conversion of Schema GUIDs and Access Right GUIDs into meaningful Object, Attribute or Access Rights names. The Functions will also integrate seamlessly with native Active Directory CmdLets (such as Get-ADObject, Get-ADUser, Get-ADGroup and Get-ADOrganizationalUnit).

The module is intended to offer an alternative to the legacy command line utility 'dsacls.exe'. Note that as the module contains functions which are designed to manipulate Actice Directory object level permissions, it should be used with extreme caution, by administrators who understand how Active Directory permissions work. The reporting functions within the module however can be called as a non-privileged / AD authenticated user (assuming the user has access to read the permissions on the objects of interest - which will generally be the case in most Active Directory deployments).

## Getting Started

Copy the module folder to your personal or computer's PowerShell Module directory. All functions which manipulate permissions support Should Process and when executed with the -WhatIf parameter will generate a representation of the Access Control Entry that would be added / removed during execution. It is recommended that this option is used prior to changing permissions to ensure that new ACEs are in the format expected / ACEs to remove are those intended. 

### Prerequisites

The PowerShell Active Directory Module is a pre-requisite for this module. As well as relying upon numerous Active Directory CmdLets, the module also relies on the AD: PSDrive for the extraction and manipulation of permissions.

### Functions

* Get-ADObjectAcl - Gets the permissions / access control list (ACL) from the specified Active Directory Object or Objects. Multiple AD Objects can be piped to the function to generate a report on multiple objects simultaneously. The function also includes the ability to copy report information to the clipboard in Tab Delimited format, which allows it to be pasted directly into Microsoft Excel.

* Add-ADObjectAce - Adds a new Access Control Entry (ACE) to an Access Control List (ACL) defined on an Active Directory Object.

* Remove-ADObjectAce - Removes an Access Control Entry (ACE) from an Access Control List (ACL) defined on an Active Directory Object. Output from the Get-ADObjectAcl can be piped to this function to perform bulk removals (for examples removing all permissions for a particular Identity Reference).

## Authors

* **Tony Oliveira** - *Initial work* - [OLIVEIRT](https://github.com/oliveirt)

## License

This project is licensed under the MIT License - see the [LICENSE.md] file for details.

## Acknowledgments

* Much of the work relating to the conversion of Schema GUIDs and Access Right GUIDs into meaningul names has been taken from work by @GoateePFE. https://blogs.technet.microsoft.com/ashleymcglone/2013/03/25/active-directory-ou-permissions-report-free-powershell-script-download/.
