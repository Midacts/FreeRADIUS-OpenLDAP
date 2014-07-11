#!/bin/bash
# FreeRADIUS Server Setup Script with OpenLDAP Support
# Date: 7th of July, 2014
# Version 1.0
#
# Author: John McCarthy
# Email: midactsmystery@gmail.com
# <http://www.midactstech.blogspot.com> <https://www.github.com/Midacts>
#
# To God only wise, be glory through Jesus Christ forever. Amen.
# Romans 16:27, I Corinthians 15:1-4
#---------------------------------------------------------------
######## VARIABLES ########
# FreeRADIUS Version
rad_ver=3.0.3
prefix=/usr/local/etc/raddb
######## FUNCTIONS ########
function freeradiusInstall(){
	# Downloads the required packages
		echo
		echo -e '\e[34;01m+++ Installing Required Packages...\e[0m'
		apt-get update
		apt-get install -y build-essential libtalloc-dev libssl-dev libldap-2.4.2 libldap2-dev
		echo -e '\e[01;37;42mThe required packages have been installed!\e[0m'

	# Downloads the latest FreeRADIUS installation files
		echo
		echo -e '\e[34;01m+++ Getting FreeRADIUS Installation Files...\e[0m'
		cd
		wget ftp://ftp.freeradius.org/pub/freeradius/freeradius-server-$rad_ver.tar.gz
		tar xzf freeradius-server-$rad_ver.tar.gz
		cd freeradius-server-$rad_ver
		echo -e '\e[01;37;42mThe latest version of FreeRADIUS has been acquired!\e[0m'

	# Installing FreeRADIUS
		echo
		echo -e '\e[34;01m+++ Installing FreeRADIUS...\e[0m'
		./configure
		make
		make install
		echo -e '\e[01;37;42mFreeRADIUS has been installed!\e[0m'
}
function configureFreeradius(){
	# Gets the OpenLDAP server's IP or FQDN
		echo
		echo -e '\e[33mWhat is the IP or FQDN of your OpenLDAP server ?\e[0m'
		read server

	# Gets the rootDN's username
		echo
		echo -e '\e[33mWhat is the OpenLDAP server'\''s rootdn \e[33;01musername\e[0m \e[33m?\e[0m'
		read user

	# Gets the rootdn user's password
		echo
		echo -e '\e[33mWhat is the \e[33;01mpassword\e[0m \e[33mof your rootdn user ?\e[0m'
		read password

	# Gets the OpenLDAP server's domain suffix
		echo
		echo -e '\e[33mWhat is the root suffix of the OpenLDAP server'\''s domain ?\e[0m'
		echo
		echo -e '\e[31m        Please put a space beteen each word in the suffix\e[0m'
		echo
		echo -e '\e[33;01mFor Example:  "example com"  for dc=example,dc=com\e[0m'
		read -ra suffix

	# Adds the ldap server
		echo
		echo -e '\e[34;01m+++ Editing the mods-available/ldap file...\e[0m'
		sed -i '/server = "*/c\        server = "'"$server"'"' $prefix/mods-available/ldap

	# Configures the rootdn
		sed -i '/identity/c\        identity = "cn='$user',dc='${suffix[0]}',dc='${suffix[1]}'"' $prefix/mods-available/ldap

	# Configures the rootdn's password
		sed -i '/password = mypass/c\        password = "'"$password"'"' $prefix/mods-available/ldap

	# Configures the base dn
		sed -i '/base_dn = "dc=example,dc=org"/c\        base_dn = "dc='${suffix[0]}',dc='${suffix[1]}'"' $prefix/mods-available/ldap

	# Edits a bug in the files
		sed -i "/control:Password-With-Header/c\                &control:Password-With-Header    += 'userPassword'" $prefix/mods-available/ldap

	# Allows Debian to use Radius (Disables openssl check)
		sed -i 's/allow_vulnerable_openssl = no/allow_vulnerable_openssl = yes/g' $prefix/radiusd.conf

	# Enables start_tls support
		echo
		echo -e "\e[33m=== Enable start_tls ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			echo
			echo -e '\e[33mWhat is the name of your OpenLDAP server'\''s CA certificate ?\e[0m'
			echo -e '\e[33;01mFor Example:  "ca.pem"\e[0m'
			read cert
		# Enables start_tls
			sed -i "/start_tls = yes/c\                start_tls = yes" $prefix/mods-available/ldap

		# Adds the OpenLDAP server's CA certificate
			sed -i "/ca_file/c\                ca_file ="'${certdir}'"\/$cert" $prefix/mods-available/ldap
		fi

	# Enables the ldap modification
		ln -s $prefix/mods-available/ldap $prefix/mods-enabled/ldap
		echo -e '\e[01;37;42mThe mods-available/ldap file has been successfully edited!\e[0m'

	# Configures the default site for ldap
		echo
		echo -e '\e[34;01m+++ Editing the sites-available/default and inner-tunnel files...\e[0m'
		sed -i 's/-ldap/ldap/g' $prefix/sites-available/default
		sed -i '/^#[[:space:]]*Auth-Type LDAP {$/{N;N;s/#[[:space:]]*Auth-Type LDAP {\n#[[:space:]]*ldap\n#[[:space:]]*}/        Auth-Type LDAP {\n                ldap\n        }/}' $prefix/sites-available/default
		sed -i 's/^#[[:space:]]*ldap/        ldap/g' $prefix/sites-available/default

	# Configures the inner-tunnel site for ldap
		sed -i 's/-ldap/ldap/g' $prefix/sites-available/inner-tunnel
		sed -i '/^#[[:space:]]*Auth-Type LDAP {$/{N;N;s/#[[:space:]]*Auth-Type LDAP {\n#[[:space:]]*ldap\n#[[:space:]]*}/        Auth-Type LDAP {\n                ldap\n        }/}' $prefix/sites-available/inner-tunnel
		sed -i 's/^#[[:space:]]*ldap/        ldap/g' $prefix/sites-available/inner-tunnel
		echo -e '\e[01;37;42mThe sites-available/default & inner-tunnel files have been successfully edited!\e[0m'

	# Configure users file
		echo
		echo -e "\e[33m=== Configure the users file ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			echo
			echo -e '\e[33mWhat is the name of the OpenLDAP group you would like to allow access ?\e[0m'
			read group
		# Allows access to only the specified group
		# http://wiki.freeradius.org/modules/Rlm_ldap
			cat << EOB > $prefix/users
DEFAULT Ldap-Group != "$group", Auth-Type := Reject
  Reply-Message = "Sorry, you do not have permission to be granted access."
EOB
		fi
}
function freeradiusClient(){
	# Gets the domain and domain controller's names
		echo -e '\e[33mPlease type in the IP of the client (the AP you want to use WPA-Enterprise with):\e[0m'
		echo -e '\e[33;01mFor Example:  192.168.1.5\e[0m'
		read client_ip
		echo
		echo -e '\e[33mPlease type in the secret for your client :\e[0m'
		echo -e '\e[33;01mFor Example:  testing123\e[0m'
		read secret
		cat <<EOI>> $prefix/clients.conf

client $client_ip {
        secret = $secret
        shortname = $client_ip
        nas_type = other
}
EOI
}
function doAll(){
	# Calls Function 'freeradiusInstall'
		echo
		echo
		echo -e "\e[33m=== Install FreeRADIUS ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			freeradiusInstall
		fi

	# Calls Function 'configureFreeradius'
		echo
		echo -e "\e[33m=== Configure FreeRADIUS for OpenLDAP ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			configureFreeradius
		fi

	# Calls Function 'freeradiusClient'
		echo
		echo -e "\e[33m=== Setup a FreeRADIUS client ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			freeradiusClient
		fi

	# End of Script Congratulations, Farewell and Additional Information
		clear
		FARE=$(cat << 'EOZ'


          \e[01;37;42mWell done! You have completed your FreeRADIUS Installation!\e[0m

  \e[30;01mCheckout similar material at midactstech.blogspot.com and github.com/Midacts\e[0m

                            \e[01;37m########################\e[0m
                            \e[01;37m#\e[0m \e[31mI Corinthians 15:1-4\e[0m \e[01;37m#\e[0m
                            \e[01;37m########################\e[0m
EOZ
)

		#Calls the End of Script variable
		echo -e "$FARE"
		echo
		echo
		exit 0
}

# Check privileges
	[ $(whoami) == "root" ] || die "You need to run this script as root."

# Welcome to the script
	clear
	welcome=$(cat << EOA


               \e[01;37;42mWelcome to Midacts Mystery's FreeRADIUS Installer!\e[0m


EOA
)

# Calls the welcome variable
	echo -e "$welcome"

# Calls the doAll function
	case "$go" in
		* )
			doAll ;;
	esac

exit 0
