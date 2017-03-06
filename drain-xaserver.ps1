<#
.SYNOPSIS
This Script will drain users (disconnected sessions) from a XenApp Server that is set to prohibit new logons.
.DESCRIPTION
This Script will drain users (disconnected sessions) from a XenApp Server that is set to prohibit new logons. It is recommended that this script be run as a Citrix admin. In addition, the Citrix Powershell modules should be installed 
.PARAMETER XMLBrokers
Optional parameter. Which Citrix XMLBroker(s) (farm) to query. Can be a list separated by commas.
.PARAMETER citrixServer
Required parameter. Which server to drain users from.
.PARAMETER Aggression 
Optional paramter. Determines how users are drained off system. Defaults to Green which is normal behavior. Users sessions will close once the disconnect. Yellow and Red agression are set in minutes in the constants section. 
.EXAMPLE
PS C:\PSScript> .\drain-xaserver.ps1 -xaserver SERVERNAME
 
Will use hardcoded Delivery Controller(s).
Will drain users from SERVERNAME using green aggression level.
.EXAMPLE
PS C:\PSScript> .\cleanup-reboot.ps1 -XMLBrokers YOURDDC.DOMAIN.LOCAL -xaserver SERVERNAME
 
Will use YOURDDC.DOMAIN.LOCAL for the delivery controller address.
Will drain users from SERVERNAME using green aggression level.
.EXAMPLE
PS C:\PSScript> .\cleanup-reboot.ps1 -XMLBrokers YOURDDC.DOMAIN.LOCAL -xaserver SERVERNAME -Aggression red
 
Will use YOURDDC.DOMAIN.LOCAL for the delivery controller address.
Will drain users from SERVERNAME using red aggression level.
.INPUTS
None.
.OUTPUTS
None.
.NOTES
NAME: drain-xaserver.ps1
VERSION: 2.13
CHANGE LOG - Version - When - What - Who
1.00 - 05/21/2009 - Initial script - Alain Assaf
2.00 - 01/05/2017 - Updated for XenApp 6.5 - Alain Assaf
2.01 - 01/09/2017 - Added more logic - Alain Assaf
2.02 - 01/25/2017 - Added another line to count sessions while in loop. Changed Stop-xasession to actually work - Alain Assaf
2.03 - 02/14/2017 - Fixed comment-based help - Alain Assaf
2.04 - 02/14/2017 - Recalculating sesscount within While loop for better results - Alain Assaf
2.05 - 02/17/2017 - Added more lines to check session count - Alain Assaf
2.06 - 02/21/2017 - Updated get-mymodule and get-mysnapins functions to new versions - Alain Assaf
2.07 - 02/21/2017 - Used new-timespan to calculate idle user time - Alain Assaf
2.08 - 02/21/2017 - Added verbose message to noet who is being disconnected - Alain Assaf
2.09 - 02/21/2017 - Added hours to user idle time - Alain Assaf
2.10 - 02/21/2017 - Removed unused code and variables - Alain Assaf
2.11 - 02/21/2017 - Added some links to helpful articles - Alain Assaf
2.12 - 03/03/2017 - Added Change log back to script - Alain Assaf
2.13 - 03/06/2017 - Removed unused get-mymodule fuction - Alain Assaf
LAST UPDATED: March 03, 2017
AUTHOR: Alain Assaf
.LINK
 http://www.linkedin.com/in/alainassaf/
 http://wagthereal.com
 http://www.cloudenthusiast.com/post/Session-Host-Reboot-Crawler
 http://www.teamas.co.uk/2012/06/presence-information-from-citrix.html
 http://stackoverflow.com/questions/21882831/how-to-compare-two-dates-in-powershell-get-difference-in-minutes
 http://www.powershellmagazine.com/2013/02/18/pstip-handling-negative-timespan-objects/
#>

Param(
 [parameter(Position = 0, Mandatory=$true )]
 [ValidateNotNullOrEmpty()]
 $citrixServer = $args[0],

 [parameter(Position = 1, Mandatory=$False )]
 [ValidateNotNullOrEmpty()]
 $XMLBrokers="YOURDDC.DOMAIN.LOCAL", # Change to hardcode a default value for your Delivery Controller
 
 [parameter(Position = 2, Mandatory=$False )]
 [ValidateSet("Green","Yellow","Red")]
 $aggression = "Green"
 )
 
#Constants
$PSSnapins = ("Citrix*")
 
### START FUNCTION: get-mysnapin ###################################################
Function Get-MySnapin {
    Param([string]$snapins)
        $ErrorActionPreference= 'silentlycontinue'
        foreach ($snap in $snapins.Split(",")) {
            if(-not(Get-PSSnapin -name $snap)) {
                if(Get-PSSnapin -Registered | Where-Object { $_.name -like $snap }) {
                    add-PSSnapin -Name $snap
                    $true
                }                                                                           
                else {
                    write-warning "$snap PowerShell Cmdlet not available."
                    write-warning "Please run this script from a system with the $snap PowerShell Cmdlet installed."
                    exit 1
                }                                                                           
            }                                                                                                                                                                  
        }
}
### END FUNCTION: get-mysnapin #####################################################

### START FUNCTION: test-port ######################################################
# Function to test RDP availability
# Written by Aaron Wurthmann (aaron (AT) wurthmann (DOT) com)
function Test-Port{
    Param([string]$srv=$strhost,$port=3389,$timeout=300)
    $ErrorActionPreference = "SilentlyContinue"
    $tcpclient = new-Object system.Net.Sockets.TcpClient
    $iar = $tcpclient.BeginConnect($srv,$port,$null,$null)
    $wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
    if(!$wait) {
        $tcpclient.Close()
        Return $false
    } else {
        $error.Clear()
        $tcpclient.EndConnect($iar) | out-Null
        Return $true
        $tcpclient.Close()
    }
}
### END FUNCTION: test-port ########################################################

#Import Module(s) and Snapin(s)
get-MySnapin $PSSnapins

#Find an XML Broker that is up
$DC = $XMLBrokers.Split(",")
foreach ($broker in $DC) {
    if ((Test-Port $broker) -and (Test-Port $broker -port 1494) -and (Test-Port $broker -port 2598))  {
        $XMLBroker = $broker
        break
    }
}

#Set Aggression level
if ($aggression -eq "Red") {
    $timeOut = 15
    write-verbose "Agression level is Red. Idle session timeout set to 15 minutes"
} elseif ($aggression -eq "Yellow") {
    $timeOut = 30
    write-verbose "Agression level is Yellow. Idle session timeout set to 30 minutes"
} else {
    $timeOut = 0
    write-verbose "Agression level is Green. Idle session timeout is default"
}

#Initialize array
$finalout = @()

# Checking that the Citrix server exists
$isServer = Get-XAServer -ComputerName $XMLBroker  | where {$_.servername -eq $citrixServer}
If ($isServer -eq $null) {
    write-warning "Invalid Citrix server. Exiting drain-xaserver"
    Exit 1
}
 
# Get the assigned Logon Mode
$xaLogonMode = $isServer.LogOnMode.ToString()
if ($xaLogonMode -eq "ProhibitNewLogOnsUntilRestart") {
    Write-Verbose "Server set to ProhibitNewLogOnsUntilRestart"
    $canDrain = $true
} elseif ($xaLogonMode -eq "ProhibitNewLogOns") {
    Write-Verbose "Server set to ProhibitNewLogOns"
    $canDrain = $true
} elseif ($xaLogonMode -eq "ProhibitLogOns") {
    Write-Verbose "Server set to ProhibitLogOns"
    $canDrain = $true
} else {
    Write-Verbose "Server set to AllowLogOns"
    $canDrain = $false
}

#Debug
Write-Debug "DEBUG: *** WHAT WE KNOW ***"
Write-Debug "DEBUG: Server = $citrixServer"
Write-Debug "DEBUG: Aggression = $aggression."
if ($timeOut -ne 0) {
    write-Debug "Session Timeout = $timeOut minutes"
} else {
   write-Debug "Session Timeout is Citrix Default"
}
Write-Debug "DEBUG: LogonMode = $xaLogonMode"
Write-Debug "DEBUG: canDrain = $canDrain"

$XenAppServerName = $citrixServer.ToUpper()
 
# Can we drain users? If not this script will exit
if ($canDrain) {
    Write-verbose "$XenAppServerName is set to logon mode: $xaLogonMode. Can drain users"
} else {
    write-warning "$XenAppServerName is set to logon mode: $xaLogonMode. CANNOT DRAIN USERS"
    write-warning "Exiting drain-xaserver"
    Exit 1
}
 
# Get the current session count on isServer
$xaSessions = (Get-XASession -ComputerName $XMLBroker -ServerName $XenAppServerName -full | where {($_.State -eq 'Active' -or $_.State -eq 'Disconnected') -and $_.Protocol -eq 'Ica'} | select SessionId,accountname,state,lastinputtime -Unique)
$sessCount = ($xaSessions | measure).count
 
# Check for disconnected users. If none, wait 10 minutes and check again
# If there are disconnected users. Log them off. Continue until there are no more logged in sessions.
while ($sessCount -ge 0) {
    $xaSessions = (Get-XASession -ComputerName $XMLBroker -ServerName $XenAppServerName -full | where {($_.State -eq 'Active' -or $_.State -eq 'Disconnected') -and $_.Protocol -eq 'Ica'} | select SessionId,accountname,state,lastinputtime -Unique)    
    $sessCount = ($xaSessions | measure).count    
    $curTime = (get-date -Format T)
    write-host "Current time is: $curTime"
    Write-Host "Current session Count = $sessCount on $XenAppServerName" -ForegroundColor White
    if ($sessCount -eq 0) {
        Write-Host "$XenAppServerName is free of users (ICA Sessions)" -ForegroundColor White
        Exit 0
    } else {
        $disconnected = @()
        Write-Host "Checking for disconnected and idle users on $XenAppServername" -ForegroundColor White
        $disconnected = $xaSessions | Where-Object {$_.State -eq 'Disconnected'}
        $active = $xaSessions | Where-Object {$_.State -eq 'Active'}
        if ($timeout -ne 0) {            # Check if aggression is not Green, otherwise don't look at Active sessions
             foreach ($idleuser in $active) {
                $idleusertime =  (New-TimeSpan -Start (get-date) -End $idleuser.LastInputTime).negate().Minutes + ((New-TimeSpan -Start (get-date) -End $idleuser.LastInputTime).negate().hours * 60)
                if ($idleusertime -gt $timeOut) {
                    $user = $idleuser.accountname.Tostring()
                    write-verbose "$user has been idle for $idleusertime minutes. They will be disconnected."
                    [array]$disconnected += $idleuser
                 }
            }
            $xaSessions = (Get-XASession -ComputerName $XMLBroker -ServerName $XenAppServerName -full | where {($_.State -eq 'Active' -or $_.State -eq 'Disconnected') -and $_.Protocol -eq 'Ica'} | select SessionId,accountname,state,lastinputtime -Unique)
            $sessCount = ($xaSessions | measure).count
        }
        if ($disconnected -eq $null) {
            Write-Host "There are no disconnected sessions on $XenAppServerName" -ForegroundColor White
            Write-Host "Waiting 10 minutes" -ForegroundColor Red
            Start-Sleep -Seconds 600
        } else {
            Write-host "Logging off" ($disconnected | measure).count "disconnected users from $XenAppServerName" -ForegroundColor White
            foreach ($user in $disconnected) {
                $namedUser = $user.AccountName
                write-host "Logging off $namedUser" -ForegroundColor White
                Stop-XASession -ComputerName $XMLBroker -ServerName $XenAppServerName -SessionId $user.SessionId
            }
            $xaSessions = (Get-XASession -ComputerName $XMLBroker -ServerName $XenAppServerName -full | where {($_.State -eq 'Active' -or $_.State -eq 'Disconnected') -and $_.Protocol -eq 'Ica'} | select SessionId,accountname,state,lastinputtime -Unique)
            $sessCount = ($xaSessions | measure).count
        }
    }
}