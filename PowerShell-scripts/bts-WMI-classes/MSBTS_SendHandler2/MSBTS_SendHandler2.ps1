﻿########################################################################################################
#                                                                                                      #
# Author: Sandro Pereira                                                                               #
#                                                                                                      #
# Description: Use of the MSBTS_SendHandler2 WMI Class.                                                #
#                                                                                                      #
#                                                                                                      #
########################################################################################################

# Function that will delete an existent host handlers in the adapters
function Delete-BizTalk-Adapter-Handler([string]$adapterName, [string]$direction, [string]$hostName)
{
    try
    {
        if($direction -eq 'Receive')
        {
            [System.Management.ManagementObject]$objHandler = get-wmiobject 'MSBTS_ReceiveHandler' -namespace 'root\MicrosoftBizTalkServer' -filter "HostName='$hostName' AND AdapterName='$adapterName'"
            $objHandler.Delete()
        }
        else
        {
            [System.Management.ManagementObject]$objHandler = get-wmiobject 'MSBTS_SendHandler2' -namespace 'root\MicrosoftBizTalkServer' -filter "HostName='$hostName' AND AdapterName='$adapterName'"
            $objHandler.Delete()
        }
 
        Write-Host "$direction handler for $adapterName / $hostName was successfully deleted" -Fore DarkGreen
    }
    catch [System.Management.Automation.RuntimeException]
    {
        if ($_.Exception.Message -eq "You cannot call a method on a null-valued expression.")
        {
            Write-Host "$adapterName $direction Handler for $hostName does not exist" -Fore DarkRed
        }
        elseif ($_.Exception.Message.IndexOf("Cannot delete a receive handler that is used by") -ne -1)
        {
            Write-Host "$adapterName $direction Handler for $hostName is in use and can't be deleted." -Fore DarkRed
        }
        elseif ($_.Exception.Message.IndexOf("Cannot delete a send handler that is used by") -ne -1)
        {
            Write-Host "$adapterName $direction Handler for $hostName is in use and can't be deleted." -Fore DarkRed
        }
        elseif ($_.Exception.Message.IndexOf("Cannot delete this object since at least one receive location is associated with it") -ne -1)
        {
            Write-Host "$adapterName $direction Handler for $hostName is in use by at least one receive location and can't be deleted." -Fore DarkRed
        }
        else
        {
            write-Error "$adapterName $direction Handler for $hostName could not be deleted: $_.Exception.ToString()"
        }
    }
}

# Function that will create a handler for a specific adapter on the host
function Create-BizTalk-Adapter-Handler([string]$adapterName, [string]$direction, [string]$hostName, [string]$originalDefaulHostName, [boolean]$isDefaultHandler, [boolean]$removeOriginalHostInstance)
{
    if($direction -eq 'Receive')
    {
        [System.Management.ManagementObject]$objAdapterHandler = ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_ReceiveHandler").CreateInstance()
        $objAdapterHandler["AdapterName"] = $adapterName
        $objAdapterHandler["HostName"] = $hostName
    }
    else
    {
        [System.Management.ManagementObject]$objAdapterHandler = ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_SendHandler2").CreateInstance()
        $objAdapterHandler["AdapterName"] = $adapterName
        $objAdapterHandler["HostName"] = $hostName
        $objAdapterHandler["IsDefault"] = $isDefaultHandler
    }
 
    try
    {
        $putOptions = new-Object System.Management.PutOptions
        $putOptions.Type = [System.Management.PutType]::CreateOnly;
 
        [Type[]] $targetTypes = New-Object System.Type[] 1
        $targetTypes[0] = $putOptions.GetType()
 
        $sysMgmtAssemblyName = "System.Management"
        $sysMgmtAssembly = [System.Reflection.Assembly]::LoadWithPartialName($sysMgmtAssemblyName)
        $objAdapterHandlerType = $sysMgmtAssembly.GetType("System.Management.ManagementObject")
 
        [Reflection.MethodInfo] $methodInfo = $objAdapterHandlerType.GetMethod("Put", $targetTypes)
        $methodInfo.Invoke($objAdapterHandler, $putOptions)
 
        Write-Host "$adapterName $direction Handler for $hostName was successfully created" -Fore DarkGreen
    }
    catch [System.Management.Automation.RuntimeException]
    {
        if ($_.Exception.Message.Contains("The specified BizTalk Host is already a receive handler for this adapter.") -eq $true)
        {
            Write-Host "$hostName is already a $direction Handler for $adapterName adapter." -Fore DarkRed
        }
        elseif($_.Exception.Message.Contains("The specified BizTalk Host is already a send handler for this adapter.") -eq $true)
        {
            Write-Host "$hostName is already a $direction Handler for $adapterName adapter." -Fore DarkRed
        }
        else {
            write-Error "$adapterName $direction Handler for $hostName could not be created: $_.Exception.ToString()"
        }
    }
 
    if($removeOriginalHostInstance)
    {
        Delete-BizTalk-Adapter-Handler $adapterName $direction $originalDefaulHostName
    }
}

# Set a Host has a Send Handler default host 
function Set-As-Default-Host-Send-Handler([string]$adapter, [string]$hostName)
{
    try
    {
        [System.Management.ManagementObject]$objHandler = get-wmiobject 'MSBTS_SendHandler2' -namespace 'root\MicrosoftBizTalkServer' -filter "HostName='$hostName' AND AdapterName='$adapter'"
        $objHandler["IsDefault"] = $true
		$objHandler.Put()
	
        write-SucessMessage "Set $hostName as Default Host for $adapter"
    }
    catch [System.Management.Automation.RuntimeException]
    {
        if ($_.Exception.Message -eq "You cannot call a method on a null-valued expression.")
        {
            write-WarnMessage "$adapter send handler for $hostName does not exist"
        }
        else
        {
            write-Error "$adapter send handler for $hostName could not be deleted: $_.Exception.ToString()"
        }
    }
}

# List all Handlers from a specific adapter
function BTS–Show–Adapter-Handlers([string]$adapter)
{
   $adapterName = $adapter.Name
   Write-Host "— " + $adapter.Name + " —"

   $sendHandlers = Get–WmiObject MSBTS_SendHandler2 –namespace ‘root\MicrosoftBizTalkServer‘ –filter “AdapterName='$adapterName'“
   if ( $sendHandlers.Length –gt 0 )
   {
      Write-Host "Send Handlers:"

      for ( $i =0; $i –lt $sendHandlers.Length; $i++ )
      {
         Write-Host "   - " + $sendHandlers[$i].HostName
      }
   }

   $recvHandlers = Get–WmiObject MSBTS_ReceiveHandler –namespace ‘root\MicrosoftBizTalkServer‘ –filter “AdapterName='$adapterName'“
     if ( $recvHandlers.Length –gt 0 )
   {
      Write-Host "Receive Handlers:"

      for ( $i =0; $i –lt $recvHandlers.Length; $i++ )
      {
         Write-Host "   - " + $recvHandlers[$i].HostName
      }
   }
}