# Simple LDAP2PG Configuration using OpenLDAP

# Table of Contents
[Overview and Prerequisites](#overview-and-prerequisites)<br>
[Install and Configure Open LDAP](#install-and-configure-open-ldap) <br>
[Install and Configure Open LDAP](#install-and-configure-ldap2pg) <br>
[Create OpenLDAP Roles and Users](#create-openldap-roles-and-users)<br>
[ldap2pg Validation](#ldap2pg-validation)

## Overview and Prerequisites
The procedures detailed below will allow you to demonstrate the LDAP2PG synchronization.  Specifically these procedures will allow you to:
1. **Set up a Read-Only Role**:  You will set up a group within your OpenLDAP instance for read-only users and add 2 users to this group. This will be the Marketing group.
2. **Set up a Read-Write Role**: You will set up a group within your OpenLDAP instance for read-write users and add 2 users to this group. This will be the HR group.
3. **Use a predefined ldap2pg configuration** A ldap2pg YML configuration example is provided to run the synchronization of the roles and users to your Postgres database schema.
4. 


**Prerequisites**
- You will need to have an LDAP server such as [OpenLDAP](https://www.openldap.org/) instance installed.
- You will need to have ldap2pg installed.  Download binary from the following location: [ldap2pg](https://ldap2pg.readthedocs.io/en/latest/) 
- You will need to have an user created that has access to LDAP to view the users and groups in the Distingished Name(DN) that is being synced with Postgres and also have access to your Postgres database with privileges to create, revoke users and roles from tables, schemas and databases.
- Ensure that the node where the ldap2pg application is installed has access to both the LDAP instance as well as the Postgres databases for synchronization.

<br>

## Install and Configure Open LDAP 
1. On a separate node from the LDAP Server and Postgres node download and install OpenLDAP as an administrator.

2. Use the following configurations for the sample OpenLDAP.  I the following example the user used for the OpenLDAP instance is "admin" and the password is "admin".

		edb.example.org
		ou=edb
		cn=admin
		password = admin
	
3. Test the connection to ldap on the server it was installed using the following command.  If ldapsearch does not exist, then install **openlap-clients** for Red Hat-based distributions or **ldap-utils** for Debian-based distributions.

		ldapsearch -H ldap://localhost -W -U admin -b "cn=admin,dc=edb,dc=example,dc=org"
		
## Install and Configure ldap2pg
1. As an administrator install ldap2pg.  I installed this on a dat anode.  I do not recommend this due to step #3.

2. sudo as enterprisedb and export the following variables to ~/.bashrc

		export PGDATABASE=bdrdb
	
3. Configure ldap file where ldap2pg is going to be run from.  Edit the following file to have the following settings shown below: **/etc/ldap/ldap.conf** 
    
		BASE	  dc=edb,dc=example,dc=org
		URI	  ldap://localhost
		BINDDN    cn=admin,dc=edb,dc=example,dc=org
		PASSWORD  admin

4. Alternatively, if the ldap.conf does not exist in this location, then you can create this file anywhere and set the environment variable.  **export LDAPCONF=/path/to/your/ldap.conf**  <br>  
This is the order in which it will attempt to find this config file:  
	
		path=/etc/ldap/ldap.conf
		path=/var/lib/edb-as/ldaprc 
		path=/var/lib/edb-as/.ldaprc 
		path=/var/lib/edb-as/ldap2pg/ldaprc  
		path=/path/to/your/ldap.conf 

- **NOTE: ** This file is just where ldap2pg looks for the ldap config information.  This is **NOT** read from the ldap2pg.yml file.  
It is simply a config file, ldap does **NOT** need to exist on this same host machine where ldap2pg resides.

5. Update the following scripts to indicate the correct postgres setting for the environment variables:  

		export PGPORT=5444
		export PGPASSWORD='n&ce?PCl81QE%H5MX8sQ3bQou^Pc'
		export PGUSER=enterprisedb

- **Scripts to Update**	
  - ldap2pg-scripts/configldap.sh
  - ldap2pg-scripts/syncldap.sh

- **NOTE:** Ideally we should create a new ldap2pg user in postgres for connecting to the database, rather than using enterprisedb, then you can export all these environment variables for this ldap2pg user.

6. Once installed test the connection by running.

		ldap2pg --config ldapp2pg/ldap2pg.yml

## Create OpenLDAP Roles and Users
The following steps describe how to create 2 new roles and 2 users within these roles within your OpenLDAP instance.
 
1. Add Organization groups

		ldapadd -x -D "cn=admin,dc=edb,dc=example,dc=org" -W -f ldap-scripts/create_ou.ldif

2. Create hr and marketing groups

		ldapadd -x -D "cn=admin,dc=edb,dc=example,dc=org" -W -f ldap-scripts/create_groups.ldif

3. Create users

		ldapadd -x -D "cn=admin,dc=edb,dc=example,dc=org" -W -f ldap-scripts/create_users.ldif

4. Add users to groups

		ldapmodify -x -D "cn=admin,dc=edb,dc=example,dc=org" -W -f ldap-scripts/add_users_to_groups.ldif


## ldap2pg Validation
The specific steps you will follow during a demo depend to some degree on the ldap2pg configuration you have deployed.  The following steps are a general guideline on how to perform the demonstration. 

### View Groups and Users in LDAP
Perform the following steps from the ldap2pg node.
	
1. Show the 2 groups and 5 users that currently exist in Open LDAP.
	
		ldapsearch -x -LLL -b "ou=groups,dc=edb,dc=example,dc=org" "(|(cn=hr)(cn=marketing))"

2. This should yield the result:

		dn: cn=marketing,ou=groups,dc=edb,dc=example,dc=org
		objectClass: posixGroup
		cn: marketing
		gidNumber: 5001
		description: Marketing
		memberUid: uid=marketinguser1,ou=groups,dc=edb,dc=example,dc=org
		memberUid: uid=marketinguser2,ou=groups,dc=edb,dc=example,dc=org
		memberUid: uid=marketinguser3,ou=groups,dc=edb,dc=example,dc=org
		
		dn: cn=hr,ou=groups,dc=edb,dc=example,dc=org
		objectClass: posixGroup
		cn: hr
		gidNumber: 5000
		description: Human Resources
		memberUid: uid=hruser1,ou=groups,dc=edb,dc=example,dc=org
		memberUid: uid=hruser2,ou=groups,dc=edb,dc=example,dc=org

### View Current Roles and Users in Postgres Database
Obtain a database session to the postgres database you are syncronizing with.  Perform the following steps to view the current set of roles and users.
	
1. Show current roles, making note that these LDAP users and groups do not yet exist.
	
		\du
	
2. Show the members that exist for each role within the database.  Again, noting that these LDAP users and groups do not yet exist.
	
		SELECT r.rolname AS role_name,  u.rolname AS member_username
		FROM pg_roles r
		JOIN pg_auth_members m ON r.oid = m.roleid
		JOIN pg_roles u ON m.member = u.oid;
	
3. Show table privileges on a table that will be included in the synchronization.  Again, noticing that new roles and users do not have any privileges.  
	
		\dp <table name>
	
### Run the Validation and 
	
1. Run the Validate Config.  Discuss how it verifies connection to ldap then to postgres, then finally performing the synchronization listing all the tasks it will perform
and that this is just a preview.  In the script you'll notice that the export statements are added here instead of at the user profile this is because will corrupt your PGD cluster.
	
		./ldap2pg/configldap.sh
	
2. Run the LDAP sync.  Discuss this actually performs the tasks outlined in the config.r
	
		./ldap2pg/syncldap.sh
	
### **Terminal 2 - psql**
	
1. Show Results of newly added roles and users

		\du
		
		SELECT r.rolname AS role_name,  u.rolname AS member_username
		FROM pg_roles r
		JOIN pg_auth_members m ON r.oid = m.roleid
		JOIN pg_roles u ON m.member = u.oid;
	
2. Show that the employees table has read permission for marketing and read/write for HR
	
		\dp employees
	
### **View ldap2pg.yml**
1. Open and Discuss ldap2pg.yml 

## Demo Cleanup
This removes the new users and groups from postgres database synced with ldap so you can run the demo again.

	bdrdb=# \i  psql-scripts/revoke-priv-role.sql




