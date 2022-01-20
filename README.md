# SINC-RemoveUsers
 Removes users on lab computers that have not logged in in 3-4 days.

- Author: Andrew W. Johnson
- Date: 2020.06.01
- Version: 5.00
- Organization: Stony Brook University/DoIT
---
### Description

Yet another re-write due to macOS pushing towards zsh and soon dropping bash/perl/python?

This script will remove users home directories/accounts from the computers if they are unused for about 4 days. This script is now designed to be run from Jamf and it should be scheduled to run off hours, in this case around 3-4 in the morning.

Activity is logged in /private/var/log/SINC-rmUsers.log. The log will be rw for root only. We don't want our clients being able to see the log, and possibly use it to stalk other users or for other personal gain?

If the script is called with no arguments then it will run in standard mode aka delete users and home directories that are older then ~4 days.

These are the optional arguments:

- All User Deletion [-a]: Delete all users, ignoring the three day rule (minus the admin and guest accounts.)
- No Delete [-n]: Perform in either modes but it will not delete. Basically a dry run to be sure you are not deleting the wrong stuff.
- Version [-v]: print out the version number.
- Help [-h]: print out how to use the script.