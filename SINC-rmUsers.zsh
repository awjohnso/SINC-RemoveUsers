#!/bin/zsh

# Author: Andrew W. Johnson
# Date: 2020.06.01
# Version: 5.00
# Organization: Stony Brook University/DoIT
#
# Yet another re-write due to macOS pushing towards zsh and soon dropping bash/perl/python?
#
# This script will remove users home directories/accounts from the computers if they are 
# unused for about 4 days. This script is now designed to be run from JAMF and it should be
# scheduled to run off hours, in this case around 3-4 in the morning.

# Activity is logged in /private/var/log/SINC-rmUsers.log. The log will be rw for root only.
# We don't want our clients being able to see the log, and possibly use it to stalk other
# users or for other personal gain?
#
# If the script is called with no arguments then it will run in standard mode aka delete 
# users and home directories that are older then ~4 days.
#
# These are some of the optional arguments:
#
# All User Deletion [-a]: Delete all users, ignoring the three day rule (minus the admin and guest accounts.)
#
#         No Delete [-n]: Perform in either modes but it will not delete.
#                    Basically a dry run to be sure you are not deleting
#                    the wrong stuff.
#
#
#
	# Setup some variables.
deleteAll=0
noDelete=0
help=0
myVers=0
myLog="/private/var/log/$( /usr/bin/basename ${0} | /usr/bin/cut -d "." -f 1).log"
/bin/echo "${myLog}"


while [[ "$#" -gt 0 ]]; do
    case $1 in
        -a) deleteAll=1 ;;
        -n) noDelete=1 ;;
        -h) help=1 ;;
        -v) myVers=1;;
    esac
    shift
done

if [[ ${help} -eq 1 ]]; then
	/bin/echo ""; \
	/bin/echo "Usage: $( /usr/bin/basename $0 )"; \
	/bin/echo "Or use with any flag combination below:"; \
	/bin/echo "    -a [delete all]"; \
	/bin/echo "    -n [Dry run do not delete]"; \
	/bin/echo ""; \
	exit 0
fi
if [[ ${myVers} -eq 1 ]]; then
	/bin/echo ""
	/bin/echo "$( /usr/bin/basename $0 ) version 5.00"
	/bin/echo ""
	exit 0
fi

/bin/echo "" >> ${myLog}
/bin/echo "$( /bin/date | /usr/bin/awk '{print $1, $2, $3, $4}' ) $( /usr/sbin/scutil --get LocalHostName ) $( /usr/bin/basename ${0} )[$$]: Starting $( /usr/bin/basename ${0} ), v5.00" >> ${myLog}
/bin/echo "Starting $( /usr/bin/basename ${0} ), v5.00"
/bin/chmod 600 ${myLog}

	# Get a list of users on the system.
nonAdmins=( $(/usr/bin/dscl . -list /Users | /usr/bin/sed 's/_.*//g' | /usr/bin/grep -wv 'daemon\|root\|jamfservice\|nobody\|psnotify\|admin\|DesktopSupport\|desktopsupport\|Guest' | /usr/bin/sed '/^$/d') )

/bin/echo "$( /bin/date | /usr/bin/awk '{print $1, $2, $3, $4}' ) $( /usr/sbin/scutil --get LocalHostName ) $( /usr/bin/basename ${0} )[$$]: deleteAll = ${deleteAll}" >> ${myLog}
/bin/echo "deleteAll = ${deleteAll}"
/bin/echo "$( /bin/date | /usr/bin/awk '{print $1, $2, $3, $4}' ) $( /usr/sbin/scutil --get LocalHostName ) $( /usr/bin/basename ${0} )[$$]: noDelete = ${noDelete}" >> ${myLog}
/bin/echo "noDelete = ${noDelete}"

if [[ ${noDelete} -eq 1 ]]; then
	/bin/echo "$( /bin/date | /usr/bin/awk '{print $1, $2, $3, $4}' ) $( /usr/sbin/scutil --get LocalHostName ) $( /usr/bin/basename ${0} )[$$]: Dry run option selected. No deletions will occur..." >> ${myLog}
	/bin/echo "Dry run option selected. No deletions will occur..."
fi

	# Delete all section
if [[ ${deleteAll} -eq 1 ]]; then
	/bin/echo "$( /bin/date | /usr/bin/awk '{print $1, $2, $3, $4}' ) $( /usr/sbin/scutil --get LocalHostName ) $( /usr/bin/basename ${0} )[$$]: Delete all users option selected..." >> ${myLog}
	/bin/echo "Delete all users option selected..."
	for i in "${nonAdmins[@]}"; do
	if [[ ! -e "/Users/${i}" ]]; then
                continue
        fi
		isConsole=$(  /usr/bin/who | /usr/bin/egrep -i console | /usr/bin/awk '{ print $1 }' )
		if [[ -n ${isConsole} && ${isConsole} = "${i}" ]]; then
			/bin/echo "$( /bin/date | /usr/bin/awk '{print $1, $2, $3, $4}' ) $( /usr/sbin/scutil --get LocalHostName ) $( /usr/bin/basename ${0} )[$$]: User /Users/${i} is logged in. Skipping..." >> ${myLog}
			/bin/echo "User /Users/${i} is logged in. Skipping..."
		else
			/bin/echo "$( /bin/date | /usr/bin/awk '{print $1, $2, $3, $4}' ) $( /usr/sbin/scutil --get LocalHostName ) $( /usr/bin/basename ${0} )[$$]: Deleting user: $i" >> ${myLog}
			/bin/echo "Deleting user: $i"
			if [ ${noDelete} -eq 0 ]; then
				/usr/sbin/sysadminctl -deleteUser ${i}
			fi
		fi
	done
	/bin/echo "$( /bin/date | /usr/bin/awk '{print $1, $2, $3, $4}' ) $( /usr/sbin/scutil --get LocalHostName ) $( /usr/bin/basename ${0} )[$$]: Ending $( /usr/bin/basename ${0} ), v5.00" >> ${myLog}
	/bin/echo "Ending $( /usr/bin/basename ${0} ), v5.00"
	exit 0
fi

for i in "${nonAdmins[@]}"; do

	if [[ ! -e "/Users/${i}" ]]; then
		continue
	fi
	/bin/echo "$( /bin/date | /usr/bin/awk '{print $1, $2, $3, $4}' ) $( /usr/sbin/scutil --get LocalHostName ) $( /usr/bin/basename ${0} )[$$]: Deleting users older then 4 days..." >> ${myLog}
	/bin/echo "Deleting users older then 4 days..."
	myDays=$( /bin/echo $(( $(/bin/date +%s) - $(/usr/bin/stat -f%c /Users/${i}) )) )
	/bin/echo "$( /bin/date | /usr/bin/awk '{print $1, $2, $3, $4}' ) $( /usr/sbin/scutil --get LocalHostName ) $( /usr/bin/basename ${0} )[$$]: Seconds: ${myDays}" >> ${myLog}
	/bin/echo "Seconds: ${myDays}"
	let myDays=${myDays}/86400
	/bin/echo "$( /bin/date | /usr/bin/awk '{print $1, $2, $3, $4}' ) $( /usr/sbin/scutil --get LocalHostName ) $( /usr/bin/basename ${0} )[$$]: Days: ${myDays}" >> ${myLog}
	/bin/echo "Days: ${myDays}"
	if [[ ${myDays} -ge 4 ]]; then
		/bin/echo "$( /bin/date | /usr/bin/awk '{print $1, $2, $3, $4}' ) $( /usr/sbin/scutil --get LocalHostName ) $( /usr/bin/basename ${0} )[$$]: Deleting /Users/${i}" >> ${myLog}
		/bin/echo "Deleting /Users/${i}"
		if [ ${noDelete} -eq 0 ]; then
			/usr/sbin/sysadminctl -deleteUser ${i}
		fi
	else
		/bin/echo "$( /bin/date | /usr/bin/awk '{print $1, $2, $3, $4}' ) $( /usr/sbin/scutil --get LocalHostName ) $( /usr/bin/basename ${0} )[$$]: Keeping /Users/${i}" >> ${myLog}
		/bin/echo "Keeping /Users/${i}"
	fi
done
/bin/echo "$( /bin/date | /usr/bin/awk '{print $1, $2, $3, $4}' ) $( /usr/sbin/scutil --get LocalHostName ) $( /usr/bin/basename ${0} )[$$]: Ending $( /usr/bin/basename ${0} ), v5.00" >> ${myLog}
/bin/echo "Ending $( /usr/bin/basename ${0} ), v5.00"

exit 0
