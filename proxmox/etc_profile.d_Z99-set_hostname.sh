#!/bin/bash
# This script starts out in /etc/profile.d/Z99-set_hostname.sh and then is moved to /usr/local/sbin/set_hostname.sh
# This should only be run once
#
# truncate -s 0 /etc/machine-id
#
# Once the command is run, do your final shutdown.
#
# Test if users has permissions 
if [ "$EUID" -ne 0 ]
  then
  echo ""
  echo "** Please login or sudo to root to configure machine. **"
  echo ""
  continue
fi

MYDOMAIN=`dnsdomainname`

# Default hostname from host template
MYTEMPLATE="build-vm01"

if { $MYDOMAIN == "" }; then
	while true
		do
		echo "Server Domain not set.  Please enter preferred domain name"
		echo -n "Enter the domain name and press [ENTER]: "
		read MYDOMAIN
		if [[ $MYDOMAIN =~ ^[[:alnum:].-]+$ ]]; then
			break;
		else
			echo "ERROR: Format incorrect, numbers, letters, dash or dots only."
			echo ""
		fi
	done
fi

echo ""
echo "Server will reboot after this process completes"

while true
	do
	echo "Hit ^C to escape for maintenance."
	echo -n "Current hostname is $(hostname). Enter the new hostname and press [ENTER]: "
	read NEWHOSTNAME
	if [[ $NEWHOSTNAME =~ ^[[:alnum:].-]+$ ]]; then
		break;
	else
		echo "ERROR: Format incorrect, numbers, letters, dash or dots only."
		echo ""
	fi
done

echo ${NEWHOSTNAME}.${MYDOMAIN} > /etc/mailname
hostnamectl set-hostname ${NEWHOSTNAME}.${MYDOMAIN}
sed -i "s/${MYTEMPLATE}/${NEWHOSTNAME}g" /etc/hosts
rm /etc/ssh/ssh_host_*
ssh-keygen -A
restorecon /etc/ssh/ssh_host_*

# Setting build date
date > /etc/built_on.txt

echo "New hostname $NEWHOSTNAME set.  Rebooting node now."
mv /etc/profile.d/Z99-set_hostname.sh /usr/local/sbin/set_hostname.sh
chmod 644 /usr/local/sbin/set_hostname.sh
reboot now
