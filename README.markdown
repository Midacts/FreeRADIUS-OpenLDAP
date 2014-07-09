FreeRADIUS-OpenLDAP
===================

Script to setup a FreeRADIUS server that can be used to authenticate OpenLDAP users.

If you want to add radius attributes to your OpenLDAP server:
-------------------------------------------------------------

#Copy the radius schema to your OpenLDAP server

cd
cd freeradius-server-$rad_ver

scp doc/schemas/ldap/openldap.ldif $user@openldapserver:/usr/local/etc/openldap/schemas/radius.ldif
