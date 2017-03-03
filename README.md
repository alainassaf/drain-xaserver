# drain-xaserver
Drains users (disconnected sessions) from a XenApp Server that is set to prohibit new logons.

#Contributions to this script
I'd like to highlight the posts that helped me write this scrip below.
* http://www.cloudenthusiast.com/post/Session-Host-Reboot-Crawler
* http://www.teamas.co.uk/2012/06/presence-information-from-citrix.html
* http://stackoverflow.com/questions/21882831/how-to-compare-two-dates-in-powershell-get-difference-in-minutes
* http://www.powershellmagazine.com/2013/02/18/pstip-handling-negative-timespan-objects/

# PS> get-help .\drain-xaserver.ps1 -full

NAME<br>
    drain-xaserver.ps1
    
SYNOPSIS<br>
    This Script will drain users (disconnected sessions) from a XenApp Server that is set to prohibit new logons.
    
SYNTAX<br>
    PS> drain-xaserver.ps1 [-citrixServer] <Object> [[-XMLBrokers] <Object>] [[-aggression] <Object>] 
    [<CommonParameters>]
    
    
DESCRIPTION<br>
    This Script will drain users (disconnected sessions) from a XenApp Server that is set to prohibit new logons. It is recommended that this script be run as a Citrix admin. In addition, the Citrix Powershell modules should be installed
    

PARAMETERS<br>

    -citrixServer <Object>
        Required parameter. Which server to drain users from.
        
        Required?                    true
        Position?                    1
        Default value                $args[0]
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -XMLBrokers <Object>
        Optional parameter. Which Citrix XMLBroker(s) (farm) to query. Can be a list separated by commas.
        
        Required?                    false
        Position?                    2
        Default value                YOURDDC.DOMAIN.LOCAL
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -aggression <Object>
        Optional paramter. Determines how users are drained off system. Defaults to Green which is normal behavior. Users sessions will close once the disconnect. 
        Yellow and Red agression are set in minutes in the constants section.
        
        Required?                    false
        Position?                    3
        Default value                Green
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).
        
    
INPUTS<br>
    None.
    
OUTPUTS<br>
    None.
    
NOTES<pre>
        NAME: drain-xaserver.ps1
        VERSION: 2.13
        LAST UPDATED: Feburary 22, 2017
        AUTHOR: Alain Assaf</pre>
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\PSScript>.\drain-xaserver.ps1 -xaserver SERVERNAME
    
    Will use hardcoded Delivery Controller(s).
    Will drain users from SERVERNAME using green aggression level.
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\PSScript>.\cleanup-reboot.ps1 -XMLBrokers YOURDDC.DOMAIN.LOCAL -xaserver SERVERNAME
    
    Will use YOURDDC.DOMAIN.LOCAL for the delivery controller address.
    Will drain users from SERVERNAME using green aggression level.
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS C:\PSScript>.\cleanup-reboot.ps1 -XMLBrokers YOURDDC.DOMAIN.LOCAL -xaserver SERVERNAME -Aggression red
    
    Will use YOURDDC.DOMAIN.LOCAL for the delivery controller address.
    Will drain users from SERVERNAME using red aggression level.
    
# Legal and Licensing
The drain-xaserver.ps1 script is licensed under the [MIT license][].

[MIT license]: LICENSE

# Want to connect?
* LinkedIn - https://www.linkedin.com/in/alainassaf
* Twitter - http://twitter.com/alainassaf
* Wag the Real - my blog - https://wagthereal.com
* Edgesightunderthehood - my other - blog https://edgesightunderthehood.com

# Help
I welcome any feedback, ideas or contributors.
