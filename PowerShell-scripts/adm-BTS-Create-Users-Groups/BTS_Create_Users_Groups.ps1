######################################################### #
#                                                         #
# Create Users and Groups for BizTalk Server Environment  #
# Created by: Sandro Pereira                              #
# Credits : Eldert Grootenboer                            #
#                                                         #
# Organisation: DevScope                                  #
# Date: 21 June 2023	                                  #
# Version: 1.0                                            #
#                                                         #
###########################################################

########################################################### 
# Function creates a group.
########################################################### 
function CreateGroup([string]$groupname, [string]$description)
{
	# Check if the group allready exists 
	if([ADSI]::Exists("WinNT://$computer/$groupname,group"))
	{
		Write-Host $groupname "allready exists" -foregroundcolor DarkGray
		return
	}
 
	# Get the computer to which we want to add the group
	$computer = [ADSI]"WinNT://$computer"
 
	# Create the group
	$group = $computer.Create("Group", $groupname)
	$group.SetInfo()
 
	# Set the description of the group
	$group.description = $description
	$group.SetInfo()
 
	Write-Host $groupname "created" -foregroundcolor Green
}

###########################################################
# Function creates a user.
########################################################### 
function CreateUser([string]$username, [string]$password, [boolean]$passwordNeverExpires, [string]$description)
{
	# Get the computer to which we want to add the user
	$computer = [ADSI]"WinNT://$computer"
 
	# Loop through all existing users
	foreach ($user in $computer.psbase.children)
	{
		# Check if this is the user we are trying to create
		if ($user.Name -eq $username)
		{
			# If it is, the user was allready created
			Write-Host $user.Name "already exists" -foregroundcolor DarkGray
			return
		}
	}
 
	# Create the user
	$user = $computer.Create("user", "$username")
 
	# Set the password
	$user.SetPassword($password)
	$user.SetInfo()
 
	# Set the description
	$user.Description = $description
	$user.SetInfo()
 
	# The account should not be disabled
	$user.psbase.invokeset("AccountDisabled", $accountDisabled)
	$user.SetInfo()
 
	# Check if the password can expire
	if($passwordNeverExpires)
	{
		# Password should never expire
		$user.UserFlags.value = $user.UserFlags.value -bor 0x10000
		$user.CommitChanges()
	}
 
	# Check if the user was succesfully created
	if ($user.Name -eq $username)
	{
		Write-Host $username "created" -foregroundcolor Green
	}
	else
	{
		Write-host "Error creating" $username -foregroundcolor Red
	}
}

###########################################################
# Function to add a user to a group
###########################################################
function AddUserToGroup([string]$username, [string]$groupname)
{
	# Check if the group exists
	if([ADSI]::Exists("WinNT://$computer/$groupname,group"))
	{
		# The group to which we want to add the user
		$groupToAddTo = [ADSI]"WinNT://$computer/$groupname,group"
 
		# Loop through all the members in this group
		foreach($member in $groupToAddTo.psbase.Invoke("Members"))
		{
			# Check if the user is allready part of the group
			if($member.GetType().InvokeMember("Name", 'GetProperty', $null, $member, $null) -eq $username)
			{
				Write-Host $username "is allready a member of" $groupname -foregroundcolor DarkGray
				return
			}
		}
 
		# Add the user to the group
		$groupToAddTo.add("WinNT://$username")
 
		Write-Host $username "has been added to" $groupname -foregroundcolor Green
	}
	else
	{
		Write-Host $groupname "does not exist" -foregroundcolor Yellow
		return
	}
}


Echo "Start creating users and groups"
###########################################################
# Variables used throughout the script 
###########################################################

# The name of the computer we are working on
[string]$computer = "localhost"
# Parameter indicating if new users should be disabled
[string]$accountDisabled = "False"

# Create groups for BizTalk
Write-Host "Creating groups" -foregroundcolor Cyan
 
# CreateGroup -groupname "" - description ""
CreateGroup -groupname "SSO Administrators" - description "Administrator of the Enterprise Single Sign-On (SSO) service."
CreateGroup -groupname "SSO Affiliate Administrators" - description "Administrators of certain SSO affiliate applications. Can create/delete SSO affiliate applications, administer user mappings, and set credentials for affiliate application users."
CreateGroup -groupname "BizTalk Server Administrators" - description "Has the least privileges necessary to perform administrative tasks. Can deploy solutions, manage applications, and resolve message processing issues. To perform administrative tasks for adapters, receive and send handlers, and receive locations, the BizTalk Server Administrators must be added to the Single Sign-On Affiliate Administrators."
CreateGroup -groupname "BizTalk Server Operators" - description "Has a low privilege role with access only to monitoring and troubleshooting actions."
CreateGroup -groupname "BizTalk Server B2B Operators" - description "Has a low privilege role with access only to monitoring and troubleshooting actions."
CreateGroup -groupname "BizTalk Server Read Only Users" - description "This is a new group starting with BizTalk Server 2020. Members in this group can view Artifacts, service state, message flow, and tracking information. Members do not have privileges to perform any administrative operations."
CreateGroup -groupname "BizTalk Application Users" - description "The default name of the first In-Process BizTalk Host Group created by Configuration Manager. Use one BizTalk Host Group for each In-Process host in your environment. Includes accounts with access to In-Process BizTalk Hosts (hosts processes in BizTalk Server, BTSNTSvc.exe)."
CreateGroup -groupname "BizTalk Isolated Host Users" - description "The default name of the first Isolated BizTalk Host Group created by Configuration Manager. Isolated BizTalk hosts not running on BizTalk Server, such as HTTP and SOAP. Use one BizTalk Isolated Host Group for each Isolated Host in your environment."
CreateGroup -groupname "BAM Portal Users" - description "Has access to BAM Portal Web site."

# Create users for BizTalk
Write-Host ""
Write-Host "Creating users" -foregroundcolor Cyan
 
# CreateUser -username "" -password "" -groupname "" -passwordNeverExpires $true -description ""
CreateUser -username "svcSSO" -password "Pass@123" -passwordNeverExpires $true -description "Service account used to run Enterprise Single Sign-On Service which accesses the SSO database."
CreateUser -username "usrSSOAdmin" -password "Pass@123" -passwordNeverExpires $true -description "User account for the SSO Administrator."
CreateUser -username "usrSSOAffiliate" -password "Pass@123" -passwordNeverExpires $true -description "User accounts for SSO Affiliate Administrators."
CreateUser -username "svcBTSHost" -password "Pass@123" -passwordNeverExpires $true -description "Service account used to run BizTalk In-Process host instance which access In-Process BizTalk host instance (BTNTSVC)."
CreateUser -username "svcBTSIsolatedHost" -password "Pass@123" -passwordNeverExpires $true -description "Service account used to run BizTalk Isolated host instance (HTTP/SOAP)."
CreateUser -username "svcRuleEngine" -password "Pass@123" -passwordNeverExpires $true -description "Service account used to run Rule Engine Update Service which receives notifications to deployment/undeployment policies from the Rule engine database."
CreateUser -username "svcBAM" -password "Pass@123" -passwordNeverExpires $true -description "Service account used to run BAM Notification Services which accesses the BAM databases."
CreateUser -username "svcBAMWeb" -password "Pass@123" -passwordNeverExpires $true -description "User account for BAM Management Web service (BAMManagementService) to access various BAM resources. BAM Portal calls BAMManagementService with the user credentials logged on the BAM Portal to manage alerts, get BAM definition XML and BAM views"
CreateUser -username "svcBAMAppPool" -password "Pass@123" -passwordNeverExpires $true -description "Application pool account for BAMAppPool which hosts BAM Portal Web site."
CreateUser -username "svcRESTAPI" -password "Pass@123" -passwordNeverExpires $true -description "Application pool account for BizTalk REST APIs."
CreateUser -username "svcTMS" -password "Pass@123" -passwordNeverExpires $true -description "BizTalk Server TMS is a service that manages the Office 365 OAuth tokens used by BizTalk."
#optinal
CreateUser -username "usrBTSAdmin" -password "Pass@123" -passwordNeverExpires $true -description "User need to be able to configure and administer BizTalk Server."
CreateUser -username "usrBTSOperator" -password "Pass@123" -passwordNeverExpires $true -description "User account that will monitor solutions."
CreateUser -username "usrBTSB2BOperator" -password "Pass@123" -passwordNeverExpires $true -description "User account that will perform all party management operations."

# Add users to groups
Write-Host ""
Write-Host "Adding users to groups" -foregroundcolor Cyan
 
# AddUserToGroup -user "" -groupname ""
AddUserToGroup -username "svcSSO" -groupname "SSO Administrators"
AddUserToGroup -username "usrSSOAdmin" -groupname "SSO Administrators"
AddUserToGroup -username "usrSSOAffiliate" -groupname "SSO Affiliate Administrators"
AddUserToGroup -username "svcBTSHost" -groupname "BizTalk Application Users"
AddUserToGroup -username "svcBTSIsolatedHost" -groupname "BizTalk Isolated Host Users"
AddUserToGroup -username "svcBTSIsolatedHost" -groupname "IIS_WPG"
AddUserToGroup -username "svcBAM" -groupname "SQLServer2005NotificationServicesUser$computername"
AddUserToGroup -username "svcBAMWeb" -groupname "IIS_WPG"
AddUserToGroup -username "svcBAMAppPool" -groupname "IIS_WPG"
AddUserToGroup -username "svcRESTAPI" -groupname "IIS_WPG"
#optinal
AddUserToGroup -username "usrBTSAdmin" -groupname "BizTalk Server Administrators"
AddUserToGroup -username "usrBTSOperator" -groupname "BizTalk Server Operators"
AddUserToGroup -username "usrBTSB2BOperator" -groupname "BizTalk Server B2B Operators"


Echo "Finished creating users and groups"