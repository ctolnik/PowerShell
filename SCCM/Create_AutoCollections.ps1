$OUComps = ""


Add-CMADCollections﻿ -LDAPSearchBase $OUComps -LDAPSearchScope OneLevel -CollectionType Device -CollectionModule APP -CollectionNameSuffix -LimitingCollectionName -DestFolderName


<#
.Synopsis
Create ConfigMgr Collections based on Active Directory OUs

.Description
This function will create ConfigMgr Collections based on Active Directory OUs.  Supply a starting search base if you have an OU structure that doesn't start at the directory's top level, otherwise you can specify the domain as the search base but this function will create a collection for every OU OneLevel down from your starting seachbase by default.  To limit the collection creation to the specified starting searchbase, use the parameter -LDAPSearchScope and specify 'Base'.  This function will create the collection in the root of the CollectionType (User or Device) you specify, create a collection query based on each OU in scope and set the collection update rate to once every 7 days at 3:00AM by default.  You can choose the collection update period to be manual or constant by using the RefreshType parameter.  If you would like to automatically move the collections to a folder other than the root for the CollectionType, specify the parameter DestFolderName.  Please be aware that the name of a folder can only exist once per CollectionType and that it must be created prior to using this function.  To support consistent naming conventions in ConfigMgr a series of CollectionModule prefixes are available (one required) in this function to support the various administrative areas of ConfigMgr.  See the parameter CollectionModule for detailed information.  To further enhance naming conventions four CollectionNameType suffixes are available.  See the parameter CollectionNameType for detailed information.  The function will check if the user executing the script is connected to a ConfigMgr site and set the PSDrive if necessary before attempting to create collections.

.Parameter LDAPSearchBase
This will be the starting place in your Active Directory structure for your collection creation.  Ensure you have appropriate Active Directory rights before proceeding.  Enter a target OU in the form of OU=SomeOU,DC=Domain,DC=TopLevel.

.Parameter LDAPSearchScope
By default, the function will create collections starting with the OU you specify and continue to the next level of OUs downstream ('OneLevel').  If you want to create only the OU you specified in the LDAPSearchBase parameter, use 'Base' as the value for the LDAPSearchScope.  If you want to create every OU in the tree under the one you specified in the LDAPSearchBase parameter, use 'Subtree' as the value for the LDAPSearchScope.  Valid values for LDAPSearchScope are 'Base', 'OneLevel' and 'SubTree'

.Parameter CollectionType
This value dictates whether the collection will target users or devices.  Valid values for CollectionType are 'Device' or 'User'.

.Parameter CollectionModule
This parameter will place a prefix in the collection name before the OU name to help enforce ConfigMgr naming conventions.  Valid values for  CollectionModule are 'APP', 'CLS', 'EP', 'OSD', 'SU', 'AI' or 'CMP' and correspond to many of the built in administrative roles availble in ConfigMgr 2012

APP = Application Deployment
CLS = Client Settings
EP = EndPoint Protection
OSD = OS Deployment
SU = Software Updates
AI = Asset Intelligence
CMP = Compliance Settings

.Parameter CollectionNameSuffix
This parameter will place a suffix in the collection name after the OU name to help enforce ConfigMgr naming conventions.  Use this parameter if you have Active Directory OUs with the same common name in different locations of your AD structure to ensure unique collection naming.  Consider running this function multiple times for each parent OU that contains non-unique OU names.

.Parameter LimitingCollectionName
Collections must be limited to another collection.  Enter the exact name of a collection as it is displayed in the ConfigMgr admin console to use to limit your collections.  Role based access and security should be considered when deciding what limiting collection to use.

.Parameter RefreshType
You can specify one of three availble refresh cycles for your new collections.  This will dictate how the membership of a collection is evaluated.  By default, collections will refresh every 7 days ('Periodic').  If you do not want automatic refresh to occur, specify 'Manual'.  If you want frequent collection updates specify 'ConstantUpdate'.  Valid RefreshType values are 'Periodic', 'Manual', or 'ConstantUpdate'.  If you want to change the Periodic refresh cycle to a value other than 7 days, use the ConfigMgr admin console to make the adjustment on each collection manually.

.Parameter RecurInterval
Specify the unit of time between collection refresh cycles.  Valid RecurInterval values are 'Days', 'Hours', or 'Minutes'.  By default, collections will refresh every 7 days at 3:00AM

.Parameter RecurCount
Specify the length of time between collection refresh cycles based on the RecurInterval unit chosen.  By default, collections will refresh every 7 days at 3:00AM

.Parameter RecurStart
Specify a start time for the collections to be reevaluated.  Use the format hh:mm and 24hr time format rules.  By default, collections will refresh every 7 days at 3:00AM

.Parameter DestFolderName
Specify a destination folder name if you want all of your new collections to be moved to a particular ConfigMgr folder that you have created.  If you do not specify this parameter, the new collections will remain in the root folder of the CollectionType you specified.  After the collections are created, you can use the ConfigMgr admin console to move the collections manually.

.Parameter ErrorLog
Use this switch to turn on error logging.  If this switch is off, you will still see messages related to the progress of the collection creation displayed on the console.  Both success and error messages are written to the file specified in the LogFile parameter.

.Parameter LogFile
Include this parameter if you want to change the default location of the ErrorLog file.  Otherwise, the default location is 'C:\Add-CMADCollections.log'

.Example

Add-CMADCollections -LDAPSearchBase "OU=Corp,DC=Corpname,DC=Local" -LDAPSearchScope Subtree -CollectionType Device -CollectionModule APP -CollectionNameType Desktops -LimitingCollectionName "All Systems" -RefreshType ConstantUpdate -DestFolderName "ActiveDirectory" -ErrorLog

This command will create a device collection for all OUs in the tree starting with the Corp OU. The names will all start with APP and end with Desktops.  The collections will all be limited to the "All Systems" collection and be moved to the ConfigMgr folder named Active Directory under the Device Collections root.  By default the refresh interval for the collection membership evaluation will be once every 7 days at 3:00AM.  Informational messages and errors will be logged to C:\Add-CMADCollections.log
.Example
Add-CMADCollections -ErrorLog -DestFolderName "Active Directory"
cmdlet Add-CMADCollections at command pipeline position 1
Supply values for the following parameters:
(Type !? for Help.)
LDAPSearchBase: OU=Clients,OU=Corp,DC=Corp,DC=local
CollectionType: Device
CollectionModule: APP
LimitingCollectionName: APP - All Client Systems
Verifying you are connected to a ConfigMgr Site
Successfully Connected to ConfigMgr Site COR
Beginning Configuration Manager Active Directory Collection Creation
Beginning Collection Creation for the Desktops  OU


CollectionID                   : COR0003D
CollectionRules                : 
CollectionType                 : 2
CollectionVariablesCount       : 0
Comment                        : 
CurrentStatus                  : 5
HasProvisionedMember           : False
IncludeExcludeCollectionsCount : 0
IsBuiltIn                      : False
IsReferenceCollection          : False
ISVData                        : 
ISVDataSize                    : 0
LastChangeTime                 : 9/3/2013 9:16:05 PM
LastMemberChangeTime           : 1/1/1980 12:00:00 AM
LastRefreshTime                : 1/1/1980 6:00:00 AM
LimitToCollectionID            : COR00030
LimitToCollectionName          : APP - All Client Systems
LocalMemberCount               : 0
MemberClassName                : SMS_CM_RES_COLL_COR0003D
MemberCount                    : 0
MonitoringFlags                : 0
Name                           : APP - Desktops 
OwnedByThisSite                : True
PowerConfigsCount              : 0
RefreshSchedule                : {
                                 instance of SMS_ST_RecurInterval
                                 {
                                     DayDuration = 0;
                                     DaySpan = 7;
                                     HourDuration = 0;
                                     HourSpan = 0;
                                     IsGMT = FALSE;
                                     MinuteDuration = 0;
                                     MinuteSpan = 0;
                                     StartTime = "20130903030000.000000+***";
                                 };
                                 }
RefreshType                    : 2
ReplicateToSubSites            : True
ServiceWindowsCount            : 0

Collection Creation for the Desktops  OU Succeeded
Setting Query Membership Rule for the Collection 'Desktops  OU'
Query Membership Rule for the  Collection 'Desktops  OU' is set
Beginning Collection Creation for the Laptops  OU
CollectionID                   : COR0003E
CollectionRules                : 
CollectionType                 : 2
CollectionVariablesCount       : 0
Comment                        : 
CurrentStatus                  : 5
HasProvisionedMember           : False
IncludeExcludeCollectionsCount : 0
IsBuiltIn                      : False
IsReferenceCollection          : False
ISVData                        : 
ISVDataSize                    : 0
LastChangeTime                 : 9/3/2013 9:16:08 PM
LastMemberChangeTime           : 1/1/1980 12:00:00 AM
LastRefreshTime                : 1/1/1980 6:00:00 AM
LimitToCollectionID            : COR00030
LimitToCollectionName          : APP - All Client Systems
LocalMemberCount               : 0
MemberClassName                : SMS_CM_RES_COLL_COR0003E
MemberCount                    : 0
MonitoringFlags                : 0
Name                           : APP - Laptops 
OwnedByThisSite                : True
PowerConfigsCount              : 0
RefreshSchedule                : {
                                 instance of SMS_ST_RecurInterval
                                 {
                                     DayDuration = 0;
                                     DaySpan = 7;
                                     HourDuration = 0;
                                     HourSpan = 0;
                                     IsGMT = FALSE;
                                     MinuteDuration = 0;
                                     MinuteSpan = 0;
                                     StartTime = "20130903030000.000000+***";
                                 };
                                 }
RefreshType                    : 2
ReplicateToSubSites            : True
ServiceWindowsCount            : 0

Collection Creation for the Laptops  OU Succeeded
Setting Query Membership Rule for the Collection 'Laptops  OU'
Query Membership Rule for the  Collection 'Laptops  OU' is set
Beginning to move Configuration Manager Active Directory Collections to the specified destination folder
Beginning to move Collection 'APP - Desktops ' to the Destination folder 'Active Directory'
__GENUS          : 2
__CLASS          : __PARAMETERS
__SUPERCLASS     : 
__DYNASTY        : __PARAMETERS
__RELPATH        : 
__PROPERTY_COUNT : 1
__DERIVATION     : {}
__SERVER         : 
__NAMESPACE      : 
__PATH           : 
ReturnValue      : 0
PSComputerName   : 

Move operation for the Collection APP - Desktops  successful
Beginning to move Collection 'APP - Laptops ' to the Destination folder 'Active Directory'
__GENUS          : 2
__CLASS          : __PARAMETERS
__SUPERCLASS     : 
__DYNASTY        : __PARAMETERS
__RELPATH        : 
__PROPERTY_COUNT : 1
__DERIVATION     : {}
__SERVER         : 
__NAMESPACE      : 
__PATH           : 
ReturnValue      : 0
PSComputerName   : 

Move operation for the Collection APP - Laptops  successful

This command will create a device collection for all OUs one level down from the Clients OU. The names will all start with APP.  The collections will all be limited to the "APP - All Client Systems" collection and be moved to the ConfigMgr folder named Active Directory under the Device Collections root.  By default the refresh interval for the collection membership evaluation will be once every 7 days at 3:00AM.  Informational messages and errors will be logged to C:\Add-CMADCollections.log
#>
Function Add-CMADCollections {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True,
            HelpMessage = 'Enter a target container in the form of OU=SomeOU,DC=Domain,DC=TopLevel')]
        [String]$LDAPSearchBase,
    
        [Parameter(Mandatory = $False,
            HelpMessage = 'Available Scopes are Base, OneLevel & Subtree. Get-Help for usage')]
        [ValidateSet('Base', 'OneLevel', 'Subtree')]
        [String]$LDAPSearchScope = 'OneLevel',

        [Parameter(Mandatory = $True,
            HelpMessage = 'Specify the type of collection you are creating Device or User')]
        [ValidateSet('Device', 'User')]
        [String]$CollectionType,
        
        [Parameter(Mandatory = $True,
            HelpMessage = 'Available Modules are APP, CLS, EP, OSD or SU.  Get-Help for usage')]
        [ValidateSet('APP', 'CLS', 'EP', 'OSD', 'SU', 'AI', 'CMP')]
        [String]$CollectionModule,

        [Parameter(Mandatory = $False,
            HelpMessage = 'Specify a suffix for your OU collection name to help standardize naming conventions and keep collection names unique.  Get-Help for usage')]
        [String]$CollectionNameSuffix,

        [Parameter(Mandatory = $True,
            HelpMessage = 'Enter the exact name of a collection as it is displayed in the ConfigMgr Console')]
        [String]$LimitingCollectionName,

        [Parameter(Mandatory = $False,
            HelpMessage = 'Specify the type of collection you are creating Device or User')]
        [ValidateSet('Periodic', 'ConstantUpdate', 'Manual')]
        [String]$RefreshType = "Periodic",

        [Parameter(Mandatory = $False,
            HelpMessage = 'Specify the unit of time between collection refresh cycles')]
        [ValidateSet('Days', 'Minutes', 'Hours')]
        [String]$RecurInterval = "Days",
        
        [Parameter(Mandatory = $False,
            HelpMessage = 'Specify the length of time between collection refresh cycles')]
        [Int]$RecurCount = 7,

        [Parameter(Mandatory = $False,
            HelpMessage = 'Specify the start time for the collection refresh cycle')]
        [String]$RecurStart = "03:00",
    
        [Parameter(Mandatory = $False,
            HelpMessage = 'Enter the folder that you want to use for the new collection')]
        [String]$DestFolderName, 

        #Switch to turn on Error logging
        [Switch]$ErrorLog,
        [String]$LogFile = 'C:\Add-CMADCollections.log'
    )
    
    Begin {
        Write-Host "Verifying you are connected to a ConfigMgr Site"
        If ($ErrorLog) {
            Add-Content "$(get-date -Format g): Verifying you are connected to a ConfigMgr Site" -Path $LogFile
        }
        Try {
            $CMSite = Get-PSDrive -PSProvider CMSite -ErrorAction Stop -ErrorVariable CurrentError
            $SiteCode = $CMSite.Name
            $SiteServer = $CMSite.SiteServer
            CD "$($SiteCode):"
            Write-Host "Successfully Connected to ConfigMgr Site $SiteCode"
            If ($ErrorLog) {
                Add-Content "$(get-date -Format g): Successfully Connected to ConfigMgr Site $SiteCode" -Path $LogFile
            }
        }
        Catch {
            Write-Error "Error Connecting to Configuration Manager Site." 
            "Check that you have the Configuration Manager Console installed and that you are running PowerShell in x86 Mode"
            If ($ErrorLog) {
                Add-Content "$(get-date -Format g): Error Connecting to Configuration Manager Site." -Path $LogFile
                Add-Content "$(get-date -Format g): $($CurrentError)" -Path $LogFile
            }
        }
        $OUList = Get-ADOrganizationalUnit -Filter * -SearchBase $LDAPSearchBase -SearchScope $LDAPSearchScope -Properties CanonicalName  | 
        Select-Object Name, CanonicalName
        $RefreshSchedule = New-CMSchedule -RecurInterval $RecurInterval -RecurCount $RecurCount -Start $RecurStart
    }
    Process {
        Write-Host "Beginning Configuration Manager Active Directory Collection Creation"
        If ($ErrorLog) {
            Add-Content "$(get-date -Format g): Beginning Configuration Manager Active Directory Collection Creation" -Path $LogFile
        }
        Foreach ($OU in $OUList) {
            If ($CollectionType = "Device") {
                Write-Host "Beginning Collection Creation for the $($OU.Name) $CollectionNameSuffix OU"
                If ($ErrorLog) {
                    Add-Content "$(get-date -Format g): Beginning Collection Creation for the $($OU.Name) OU" -Path $LogFile
                }
                [String]$CollectionName = "$CollectionModule - $($OU.Name) $CollectionNameSuffix"
                Try {
                    New-CMDeviceCollection -Name $CollectionName -RefreshType $RefreshType -RefreshSchedule $RefreshSchedule `
                        -LimitingCollectionName $LimitingCollectionName -ErrorAction Stop -ErrorVariable CurrentError
                    Write-Host "Collection Creation for the $($OU.Name) $CollectionNameSuffix OU Succeeded"
                    If ($ErrorLog) {
                        Add-Content "$(get-date -Format g): Collection Creation for the $($OU.Name) OU Succeeded" -Path $LogFile
                    }
                }
                Catch {
                    Write-Error "Collection Creation for the $($OU.Name) $CollectionNameSuffix OU Failed"
                    If ($ErrorLog) {
                        Add-Content "$(get-date -Format g): Collection Creation for the $($OU.Name) $CollectionNameSuffix OU Failed" -Path $LogFile
                        Add-Content "$(get-date -Format g): $($CurrentError)" -Path $LogFile
                    }
                }
                Write-Host "Setting Query Membership Rule for the Collection '$($OU.Name) $CollectionNameSuffix OU'"
                If ($ErrorLog) {
                    Add-Content "$(get-date -Format g): Setting Query Membership Rule for the Collection '$($OU.Name) $CollectionNameSuffix OU'" -Path $LogFile
                }
                Try {
                    Add-CMDeviceCollectionQueryMembershipRule -CollectionName $CollectionName `
                        -QueryExpression "select * from SMS_R_System where SMS_R_System.SystemOUName = '$($OU.CanonicalName)'" `
                        -RuleName "$($OU.Name) $CollectionNameSuffix OU" -ErrorAction Continue -ErrorVariable CurrentError
                    Write-Host "Query Membership Rule for the  Collection '$($OU.Name) $CollectionNameSuffix OU' is set"
                    If ($ErrorLog) {
                        Add-Content "$(get-date -Format g): Query Membership Rule for the Collection '$($OU.Name) $CollectionNameSuffix OU' is set" -Path $LogFile
                    }
                }
                Catch {
                    Write-Error "Query Membership Rule creation for the Collection '$($OU.Name) $CollectionNameSuffix OU' Failed"
                    If ($ErrorLog) {
                        Add-Content "$(get-date -Format g): Query Membership Rule creation for the Collection '$($OU.Name) $CollectionNameSuffix OU' Failed" -Path $LogFile
                        Add-Content "$(get-date -Format g): $($CurrentError)" -Path $LogFile
                    }
                }
            }
            Else {
                Write-Host "Beginning Collection Creation for the $($OU.Name) People OU"
                If ($ErrorLog) {
                    Add-Content "Beginning Collection Creation for the $($OU.Name) People OU" -Path $LogFile
                }
                [String]$CollectionName = "$CollectionModule - $($OU.Name) People"
                Try {
                    New-CMUserCollection -Name $CollectionName -RefreshType $RefreshType -RefreshSchedule $RefreshSchedule `
                        -LimitingCollectionName $LimitingCollectionName -ErrorAction Stop -ErrorVariable CurrentError
                    Write-Host "Collection Creation for the $($OU.Name) People OU Succeeded"
                    If ($ErrorLog) {
                        Add-Content "$(get-date -Format g): Collection Creation for the $($OU.Name) People OU Succeeded" -Path $LogFile
                    }
                }            
                Catch {
                    Write-Error "Collection Creation for the '$($OU.Name) People OU Failed"
                    If ($ErrorLog) {
                        Add-Content "$(get-date -Format g): Collection Creation for the $($OU.Name) People OU Failed" -Path $LogFile
                        Add-Content "$(get-date -Format g): $($CurrentError)" -Path $LogFile
                    }
                }
                Try {
                    Add-CMUserCollectionQueryMembershipRule -CollectionName $CollectionName `
                        -QueryExpression "select * from SMS_R_System where SMS_R_System.SystemOUName = '$($OU.CanonicalName)'" `
                        -RuleName "$($OU.Name) People OU" -ErrorAction Continue -ErrorVariable CurrentError
                    Write-Host "Query Membership Rule for the  Collection '$($OU.Name) People OU' is set"
                    If ($ErrorLog) {
                        Add-Content "$(get-date -Format g): Query Membership Rule for the Collection '$CollectionName' is set" -Path $LogFile
                    }
                }
                Catch {
                    Write-Error "Query Membership Rule creation for the Collection $($OU.Name) People OU Failed"
                    If ($ErrorLog) {
                        Add-Content "$(get-date -Format g): Query Membership Rule creation for the Collection '$CollectionName' Failed" -Path $LogFile
                        Add-Content "$(get-date -Format g): $($CurrentError)" -Path $LogFile
                    }
                }                           
            }        
        }
    }         
    End {
        If ($DestFolderName -eq "" -Or $DestFolderName -eq $Null) {
            Write-Host "A destination folder has not been specified for moving the Configuration Manager Active Directory Collections"
            Write-Host "Configuration Manager Active Directory Collection Creation complete"
            If ($ErrorLog) {
                Add-Content "$(get-date -Format g): A destination folder has not been specified for moving the Configuration Manager Active Directory Collections" -Path $LogFile
                Add-Content "$(get-date -Format g): Configuration Manager Active Directory Collection Creation complete" -Path $LogFile
            }
        }
        Else {
            Write-Host "Beginning to move Configuration Manager Active Directory Collections to the specified destination folder"
            If ($ErrorLog) {
                Add-Content "$(get-date -Format g): Beginning to move Configuration Manager Active Directory Collections to the specified destination folder" -Path $LogFile
            }
            Foreach ($OU in $OUList) {
                If ($CollectionType = "Device") {
                    [String]$CollectionName = "$CollectionModule - $($OU.Name) $CollectionNameSuffix"
                    Write-Host "Beginning to move Collection '$CollectionName' to the Destination folder '$DestFolderName'"
                    If ($ErrorLog) {
                        Add-Content "$(get-date -Format g): Beginning to move Collection '$CollectionName' to the Destination folder '$DestFolderName'" -Path $LogFile
                    }
                    Try {
                        $CurrentFolderID = "0"
                        $DeviceCollectionID = Get-CMDeviceCollection -Name $CollectionName | Select CollectionID
                        $ObjectTypeID = "5000"
                        $DestFolderID = Get-WmiObject -Class SMS_ObjectContainerNode -Namespace "Root\SMS\Site_$SiteCode" `
                            -ComputerName $SiteServer | ? { ($_.Name -eq $DestFolderName) -and ($_.ObjectType -eq $ObjectTypeID) } | Select Name, ContainerNodeID
                    
                        Invoke-WmiMethod -Class SMS_objectContainerItem -Namespace "Root\SMS\Site_$SiteCode" `
                            -ComputerName $SiteServer  -Name MoveMembers -ArgumentList $CurrentFolderID, $DeviceCollectionID.CollectionID, $ObjectTypeID, $DestFolderID.ContainerNodeID
                    
                        Write-Host "Move operation for the Collection $($CollectionName) successful"
                        If ($ErrorLog) {
                            Add-Content "$(get-date -Format g): Moving Collection '$CollectionName' to the Destination folder '$DestFolderName' successful" -Path $LogFile
                        }
                    }
                    Catch {
                        Write-Error "Move operation for the Collection $($CollectionName) Failed"
                        If ($ErrorLog) {
                            Add-Content "$(get-date -Format g): Move operation for the Collection '$CollectionName' Failed" -Path $LogFile
                            Add-Content "$(get-date -Format g): $($CurrentError)" -Path $LogFile
                        }
                    }
                }
                Else {
                    [String]$CollectionName = "$CollectionModule - $($OU.Name) People"
                    Write-Host "Beginning to move Collection '$CollectionName' to the Destination folder '$DestFolderName'"
                    If ($ErrorLog) {
                        Add-Content "$(get-date -Format g): Beginning to move Collection '$CollectionName' to the Destination folder '$DestFolderName'" -Path $LogFile
                    }
                    Try {
                        $CurrentFolderID = "0"
                        $DeviceCollectionID = Get-CMDeviceCollection -Name $CollectionName | Select CollectionID
                        $ObjectTypeID = "5001"
                        $DestFolderID = Get-WmiObject -Class SMS_ObjectContainerNode -Namespace "Root\SMS\Site_$SiteCode" `
                            -ComputerName $SiteServer | ? { ($_.Name -eq $DestFolderName) -and ($_.ObjectType -eq $ObjectTypeID) } | Select Name, ContainerNodeID
                    
                        Invoke-WmiMethod -Class SMS_objectContainerItem -Namespace "Root\SMS\Site_$SiteCode" `
                            -ComputerName $SiteServer  -Name MoveMembers -ArgumentList $CurrentFolderID, $DeviceCollectionID.CollectionID, $ObjectTypeID, $DestFolderID.ContainerNodeID
                    
                        Write-Host "Move operation for the Collection '$CollectionName' successful"
                        If ($ErrorLog) {
                            Add-Content "$(get-date -Format g): Move operation for the Collection '$CollectionName' successful" -Path $LogFile
                        }
                    }
                    Catch {
                        Write-Error "Move operation for the Collection $($CollectionName) Failed"
                        If ($ErrorLog) {
                            Add-Content "$(get-date -Format g): Move operation for the Collection '$CollectionName' Failed" -Path $LogFile
                            Add-Content "$(get-date -Format g): $($CurrentError)" -Path $LogFile
                        }
                    }
                }
            }
        }
    }
}