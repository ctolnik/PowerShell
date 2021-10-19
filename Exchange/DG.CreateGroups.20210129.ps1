#Cоздание mail-групп
# Определяем переменные
function Get-ExchangeServerInSite {
    $ADSite = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]
    $siteDN = $ADSite::GetComputerSite().GetDirectoryEntry().distinguishedName
    $configNC = ([ADSI]"LDAP://RootDse").configurationNamingContext
    $search = new-object DirectoryServices.DirectorySearcher([ADSI]"LDAP://$configNC")
    $objectClass = "objectClass=msExchExchangeServer"
    $version = "versionNumber>=1937801568"
    $site = "msExchServerSite=$siteDN"
    $search.Filter = "(&($objectClass)($version)($site))"
    $search.PageSize = 1000
    [void] $search.PropertiesToLoad.Add("name")
    [void] $search.PropertiesToLoad.Add("msexchcurrentserverroles")
    [void] $search.PropertiesToLoad.Add("networkaddress")
    $search.FindAll() | % {
        New-Object PSObject -Property @{
            Name  = $_.Properties.name[0]
            FQDN  = $_.Properties.networkaddress |
            % { if ($_ -match "ncacn_ip_tcp") { $_.split(":")[1] } }
            Roles = $_.Properties.msexchcurrentserverroles[0]
        }
    }
}


$SearchExchangeServer = Get-ExchangeServerInSite  | Select-Object -First 1 | foreach { $_.FQDN }                             # Сервер Exchnage площадки
$ExchangeServer = $SearchExchangeServer.TrimEnd('.npo.izhmash')

$ExchangeServer = "EX1"

$AD = Get-ADDomainController  -Discover   # Определяем площадку

# Определяем OU для сайта, !!!!!!!!!! НУЖНО ПРОВЕРЯТЬ

$SiteOU = $SiteName = $null
switch ($AD.Site) {           
    aaa { $SiteOU = "" ; $SiteName = "Аов" }
    bb { $SiteOU = "" ; $SiteName = "Аков" } 
    zzz { $SiteOU = "" ; $SiteName = "А" }
    zzz { $SiteOU = "" ; $SiteName = "А" }
    zz { $SiteOU = "" ; $SiteName = "22" }
    zzz { $SiteOU = "" ; $SiteName = "ss" }
    Moscow { $SiteOU = "" ; $SiteName = "" }
    ppp { $SiteOU = "h" ; $SiteName = "" }
                
} # end of switch

$OUDG = "OU=DG,OU=Рассылки,OU=Группы" + $SiteOU.TrimStart("OU=Пользователи") # OU для размещения грыппы рассылки

# Название групп рассылок
$SiteDistGroupName = "Mail-Все пользователи " + $SiteName
$SiteDistGroup = "Mail-AllUsers" + $AD.Site

$SiteDistGroupName2 = "DM-Все пользователи " + $SiteName
$SiteDistGroup2 = "DM-AllUsers" + $AD.Site


# Определяем функции


function Import-EXSession {
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Server
    )
    Import-PSSession (New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$Server.999/PowerShell/" -Authentication Kerberos) -DisableNameChecking -CommandName New-DistributionGroup
}

function Check-EXSessionExists {
    if (!(Get-PSSession | Where { $_.ConfigurationName -eq "Microsoft.Exchange" })) {
        Import-EXSession -Server $ExchangeServer
    }
}


Check-EXSessionExists -server $ExchangeServer
#Import-EXSession -Server $ExchangeServer

$PSDefaultParameterValues = @{"*-AD*:Server" = $AD.Name }

$DMGroups = Get-ADGroup -Filter { Name -like "DM-*" } -SearchBase $SiteOU
foreach ($DMGroup in $DMGroups) {
    $DMGroup.Name
    if ((Get-ADGroup $DMGroup -Properties Member  | Select-Object -ExpandProperty Member).count -gt 0) {
        if ($Description) { Clear-Variable Description }
        $Description = (Get-ADOrganizationalUnit ($DMGroup.DistinguishedName).replace("CN=$($DMGroup.name),", "") -Properties Description).Description
        $OU = (Get-ADOrganizationalUnit ($DMGroup.DistinguishedName).replace("CN=$($DMGroup.name),", "")).DistinguishedName
        $DistGroup = $DMGroup.name -replace ("DM-", "Mail-")
        $DistGroup = $DistGroup.Trim()
        if ($DistGroup -eq $SiteDistGroupName) {
            $DistGroup = $SiteDistGroupName
        }
        $Numbers = $DMGroup.name -replace ("DM-", "")
        try { 
            $Description = $Description.Substring(0, 63 - $($Numbers.length)) 
        } 
        catch {
        }
        $GroupName = $Description + " " + $Numbers
        $GroupName = $GroupName.Trim()
        $GroupName
        if (-not $Description) {
            continue
        }
        try {
            $ADGroup = Get-ADGroup $DistGroup -Properties DisplayName
            if ($ADGroup.DisplayName -notlike "$Description*") { 
                $ADGroup | Set-ADGroup -DisplayName "$GroupName" -PassThru -Verbose
            }
            if ($ADGroup.Name -notlike "$Description*") { 
                $ADGroup | Rename-ADObject -NewName "$GroupName" -PassThru
            }
            
        } 
        catch {
            $DistGroup
            New-DistributionGroup -Name $GroupName -OrganizationalUnit $OUDG -SamAccountName $DistGroup -DomainController $AD.Name
        }   
        $ShadowGroup = (Get-ADGroup $DistGroup).DistinguishedName 
        Get-ADGroup –Identity $DistGroup -Properties Member | Select-Object -ExpandProperty Member | Get-ADUser |
        Where-Object { $_.distinguishedName –NotMatch $OU } | ForEach-Object { Remove-ADPrincipalGroupMembership –Identity $_ –MemberOf $DistGroup –Confirm:$false –PassThru -Verbose }
        Get-ADUser –SearchBase $OU –LDAPFilter "(&(description>=0)(description<=9)(!memberOf=$ShadowGroup)(mail=*))" | ForEach-Object { Add-ADPrincipalGroupMembership –Identity $_ –MemberOf $DistGroup –PassThru -Verbose }
    }

}

$MailGroups = Get-ADGroup -Filter { sAMAccountName -like "Mail-*" } -SearchBase $OUDG


foreach ($MailGroup in $MailGroups) {
    $MailGroup.Name    
    $DMGroup2 = $MailGroup.sAMAccountName -replace ("Mail-", "DM-")
    if ($DMGroup2 -eq $SiteDistGroup2) {
        $DMGroup2 = $SiteDistGroupName2
    }
    try {
        if ((Get-ADGroup $DMGroup2 -Properties Member  | Select-Object -ExpandProperty Member).count -gt 0) {
        } 
        else {
            #Remove-ADGroup $MailGroup -Confirm:$false -Verbose
        }
    } 
    catch {
        #Remove-ADGroup $MailGroup -Confirm:$false -Verbose
    }
} 

