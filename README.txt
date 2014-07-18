#######################
# FreeRADIUS-OpenLDAP 
#######################
#
# Script to setup a FreeRADIUS server that can be used to authenticate OpenLDAP users.
#

########
# Notes
########
# Enable OpenLDAP on your FreeRADIUS server
# -----------------------------------------
# Your FreeRADIUS server must be able to talk to your OpenLDAP server in order to 
# retreive users and groups.
# I recommend using my puppet openldap class (https://github.com/Midacts/openldap_client)

# Copy over your OpenLDAP server's CA certificate
# -----------------------------------------------
# In order to use start_tls on your FreeRADIUS server to the OpenLDAP server, you must 
# tell FreeRADIUS where the OpenLDAP server's CA certificate is located. 
# In this script, I have it set to $prefix/certs (/usr/local/etc/raddb/certs by default).
#
# Be sure to copy the CA certificate to $prefix/certs before initiating the script if you wish to use start_tls.

# /usr/local/etc/raddb/users file
# -------------------------------
# http://wiki.freeradius.org/modules/Rlm_ldap
#
# You can edit this file to allow/disallow only certain users or groups
# Alternatively, you can use the post-auth section in the sites-available/default file

# TESTING
# -------
# On the FreeRADIUS server, run this command to start the server in debug mode.
# (so you can see the logs inn real-time).
radiusd -XXX

# Then run this command to test your configuration
radtest username password localhost 18120 testing123


###########
# OPTIONAL
###########
# If you want to add radius attributes to your OpenLDAP server:
# -------------------------------------------------------------
# Copy the radius schema to your OpenLDAP server
# Browse to the freeradius-server-xxx directory and copy the 
# openldap.ldif file to your OpenLDAP server
# I would recomment renaming the file to something like radius.ldif as there is probably 
# already an openldap.ldif file 
# on your OpenLDAP server
cd
cd freeradius-server-$rad_ver
scp doc/schemas/ldap/openldap.ldif $user@openldapserver:/usr/local/etc/openldap/schemas/radius.ldif

# Then on the OpenLDAP server, add the radius.ldif file
ldapadd -D cn=admin,cn=config -w "password" -f /usr/local/etc/openldap/schema/radius.ldif -ZZ

# With this your should now be able to add radius attributes to objects in your OpenLDAP directory

##########
# CLIENTS
##########
# These are the settings I used to get FreeRADIUS working with an OpenLDAP server and a Ubiquiti Unifi AP
#
# Phase 1: EAP-TTLS
# Phase 2: PAP
