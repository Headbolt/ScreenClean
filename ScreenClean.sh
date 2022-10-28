#!/bin/bash
#
###############################################################################################################################################
#
# ABOUT THIS PROGRAM
#
#	ScreenClean.sh
#	https://github.com/Headbolt/ScreenClean
#
#   This Script is designed for use in JAMF
#
#   This script was designed to clean up instances of ScreenConnect/ConnectWise Control
#	In the event that it gets stuck and is in a state that leaves it unmanageable.
#
###############################################################################################################################################
#
# HISTORY
#
#   Version: 1.2 - 28/10/2022
#
#   - 20/12/2019 - V1.0 - Created by Headbolt by pulling list of commands from Screenconnects own cleanup script
#							and re-writing to make it more versatile and more robust
#   - 23/12/2019 - V1.1 - Updated by Headbolt
#							Fixing further issues and tidying up, also more comprehensive error checking and notation
#   - 28/10/2022 - V1.2 - Updated by Headbolt
#							Fixing further issues and tidying up, also more comprehensive error checking and notation
#
###############################################################################################################################################
#
#   DEFINE VARIABLES & READ IN PARAMETERS
#
###############################################################################################################################################
#
PUBLIC_THUMBPRINT_PROCESS="$4" 	# Grabs the required ThumbPrint to be removed if present from JAMF variable #4 eg. bbbbaaaa360013f8
								# If One is not Specified, then the script will search and remove any discovered instances.
ScriptName="Enter Prefix as needed - ScreenConnect Cleanup" # Set the name of the script for later logging
ExitCode=0
#
###############################################################################################################################################
#
# Defining Functions
#
###############################################################################################################################################
#
# Clean Instance Function
#
CleanInstance(){
#
PUBLIC_THUMBPRINT="" # Ensure the ThumbPrint Variable is Blank
/bin/echo "Beginning cleanup of ThumbPrint" # Display Current Thumbprint we are cleaning
/bin/echo $PUBLIC_THUMBPRINT_PROCESS
/bin/echo # Outputting a Blank Line for Reporting Purposes
#
SC_PUBLIC_THUMBPRINT=$(ls /opt/ | grep -o -w -E "screenconnect-$PUBLIC_THUMBPRINT_PROCESS") # Check for ScreenConnect branded version of the ThumbPrint
CW_PUBLIC_THUMBPRINT=$(ls /opt/ | grep -o -w -E "connectwisecontrol-$PUBLIC_THUMBPRINT_PROCESS") # Check for ConnectWise branded version of the ThumbPrint
#
if [ "$SC_PUBLIC_THUMBPRINT" != "" ] # Check if a ScreenConnect version of the ThumbPrint was found, and set it as the ThumbPrint Variable
	then
		PUBLIC_THUMBPRINT=$SC_PUBLIC_THUMBPRINT
fi
#
if [ "$CW_PUBLIC_THUMBPRINT" != "" ]  # Check if a ConnectWise version of the ThumbPrint was found, and set it as the ThumbPrint Variable
	then
		PUBLIC_THUMBPRINT=$CW_PUBLIC_THUMBPRINT
fi
#
if [ "$PUBLIC_THUMBPRINT" != "" ] # Check if the ThubPrint Variable is NOT Blank, and if it isnt, process it.
	then
		/bin/echo "Unloading client launch agents..."
		NAMES_OF_USERS_STR=$(ps aux | grep $PUBLIC_THUMBPRINT_PROCESS | grep -Eo '^[^ ]+')
		NAMES_OF_USERS_ARR=($NAMES_OF_USERS_STR)
		#
		for key in "${!NAMES_OF_USERS_ARR[@]}"
			do
				POTENTIAL_USER="${NAMES_OF_USERS_ARR[$key]}"
				if [ $POTENTIAL_USER != "root" ]
					then
						NON_ROOT_USER_ID=$(id -u $POTENTIAL_USER)
						/bin/echo "Unloading client launch agent for user $POTENTIAL_USER"
                        /bin/echo '"'launchctl asuser $NON_ROOT_USER_ID launchctl unload /Library/LaunchAgents/$PUBLIC_THUMBPRINT-onlogin.plist'"'
						launchctl asuser $NON_ROOT_USER_ID launchctl unload /Library/LaunchAgents/$PUBLIC_THUMBPRINT-onlogin.plist >/dev/null 2>&1
				fi
			done
		#
		/bin/echo # Outputting a Blank Line for Reporting Purposes
		/bin/echo "Unloading client launch daemon..."
		/bin/echo '"'launchctl unload "/Library/LaunchDaemons/$PUBLIC_THUMBPRINT.plist"'"' 
		launchctl unload "/Library/LaunchDaemons/$PUBLIC_THUMBPRINT.plist" >/dev/null 2>&1
		#
		/bin/echo # Outputting a Blank Line for Reporting Purposes
		/bin/echo "Deleting client launch agents..."
		/bin/echo '"'rm "/Library/LaunchAgents/$PUBLIC_THUMBPRINT-onlogin.plist"'"'
		rm "/Library/LaunchAgents/$PUBLIC_THUMBPRINT-onlogin.plist" >/dev/null 2>&1
		/bin/echo # Outputting a Blank Line for Reporting Purposes
		/bin/echo '"'rm "/Library/LaunchAgents/$PUBLIC_THUMBPRINT-prelogin.plist"'"'
		rm "/Library/LaunchAgents/$PUBLIC_THUMBPRINT-prelogin.plist" >/dev/null 2>&1
		#
		/bin/echo "Deleting client launch daemon..."
		/bin/echo '"'rm "/Library/LaunchDaemons/$PUBLIC_THUMBPRINT.plist"'"'
		rm "/Library/LaunchDaemons/$PUBLIC_THUMBPRINT.plist" >/dev/null 2>&1
		#
		/bin/echo # Outputting a Blank Line for Reporting Purposes
		/bin/echo "Deleting client installation directory..."
		/bin/echo '"'rm -rf "/opt/$PUBLIC_THUMBPRINT.app/"'"'
		rm -rf "/opt/$PUBLIC_THUMBPRINT.app/" >/dev/null 2>&1
		#
		/bin/echo # Outputting a Blank Line for Reporting Purposes
		/bin/echo Cleanup of ThumbPrint '"'$PUBLIC_THUMBPRINT_PROCESS'"' Complete!
	else
		/bin/echo Thumbprint '"'$PUBLIC_THUMBPRINT_PROCESS'"' Not Found
fi
#
}
#
###############################################################################################################################################
#
# Section End Function
#
SectionEnd(){
#
/bin/echo # Outputting a Blank Line for Reporting Purposes
/bin/echo  ----------------------------------------------- # Outputting a Dotted Line for Reporting Purposes
/bin/echo # Outputting a Blank Line for Reporting Purposes
#
}
#
###############################################################################################################################################
#
# Script End Function
#
ScriptEnd(){
#
/bin/echo Ending Script '"'$ScriptName'"'
/bin/echo # Outputting a Blank Line for Reporting Purposes
/bin/echo  ----------------------------------------------- # Outputting a Dotted Line for Reporting Purposes
/bin/echo # Outputting a Blank Line for Reporting Purposes
#
exit $ExitCode
#
}
#
###############################################################################################################################################
#
# End Of Function Definition
#
###############################################################################################################################################
# 
# Begin Processing
#
###############################################################################################################################################
#
/bin/echo # Outputting a Blank Line for Reporting Purposes
SectionEnd # Calling the Section End Function to make Screen Output / Reporting easier to read
#
if [ "$PUBLIC_THUMBPRINT_PROCESS" == "" ] # Check if a specific ThumbPrint is being processed, and if not Search.
	then
		/bin/echo No Thumbprint Specified
		/bin/echo # Outputting a Blank Line for Reporting Purposes
		/bin/echo "Searching for installed Control clients..."
		SC_PUBLIC_THUMBPRINTS=$(ls /opt/ | grep -o -w -E "screenconnect-[[:alnum:]]{16}" | grep -Eo ".{16}$")
		CW_PUBLIC_THUMBPRINTS=$(ls /opt/ | grep -o -w -E "connectwisecontrol-[[:alnum:]]{16}" | grep -Eo ".{16}$")
		#
		PUBLIC_THUMBPRINTS=$(Echo $SC_PUBLIC_THUMBPRINTS;echo $CW_PUBLIC_THUMBPRINTS)
		PUBLIC_THUMBPRINTS_ARR=($PUBLIC_THUMBPRINTS)
		if [ ${#PUBLIC_THUMBPRINTS} -eq 0 ]
			then
				/bin/echo # Outputting a Blank Line for Reporting Purposes
				/bin/echo "No Control clients found!"
				/bin/echo "Terminating cleanup"
				#
				SectionEnd
				ScriptEnd
			else
				/bin/echo # Outputting a Blank Line for Reporting Purposes
				/bin/echo "Found client(s) with the following public thumbprint(s):"
				/bin/echo # Outputting a Blank Line for Reporting Purposes
				/bin/echo "$PUBLIC_THUMBPRINTS"
				/bin/echo # Outputting a Blank Line for Reporting Purposes
				/bin/echo "Beginning cleanup..."
				#
				for thumbprintKey in "${!PUBLIC_THUMBPRINTS_ARR[@]}"
					do
						PUBLIC_THUMBPRINT_PROCESS="${PUBLIC_THUMBPRINTS_ARR[$thumbprintKey]}"
						SectionEnd
						CleanInstance
					done
		fi	
	else 
		CleanInstance
fi
#
SectionEnd
ScriptEnd
