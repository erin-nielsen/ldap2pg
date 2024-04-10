# Simple LDAP2PG Configuration using OpenLDAP

# Table of Contents
[Overview and Prerequisites](#overview-and-prerequisites)<br>
[Install and Configure OpenLDAP](#install-and-configure-open-ldap) <br>
[Create OpenLDAP Roles and Users](#create-openldap-roles-and-users)<br>
[Install and Configure ldap2pg](#install-and-configure-ldap2pg) <br>

[ldap2pg Validation](#ldap2pg-validation)

## Overview and Prerequisites
The procedures detailed below will allow you to demonstrate the LDAP2PG synchronization.  Specifically these procedures will allow you to:
1. **Set up a Read-Only Role**:  You will set up a group within your OpenLDAP instance for read-only users and add 3 users to this group. This will be the Marketing group.
2. **Set up a Read-Write Role**: You will set up a group within your OpenLDAP instance for read-write users and add 2 users to this group. This will be the HR group.
3. **Use a predefined ldap2pg configuration** A ldap2pg YML configuration example is provided to run the synchronization of the roles and users to your PostgreSQL database schema.

**Prerequisites**
- You will need to have an LDAP server such as [OpenLDAP](https://www.openldap.org/) instance installed.
- You will need to have ldap2pg installed.  Download binary from the following location: [ldap2pg](https://ldap2pg.readthedocs.io/en/latest/) 
- You will need to have an user created that has access to LDAP to view the users and groups in the Distingished Name(DN) that is being synced with PostgreSQL and also have access to your PostgreSQL database with privileges to create, revoke users and roles from tables, schemas and databases.
- Ensure that the node where the ldap2pg application is installed has access to both the LDAP instance as well as the PostgreSQL databases for synchronization.

<br>

## Install and Configure Open LDAP 
1. Log onto the node you wish to run the OpenLDAP application.

2. Download and install [OpenLDAP](https://www.openldap.org/) as an administrator.

2. Use the following configurations for the sample OpenLDAP.  In this example the Administrator user used for the OpenLDAP instance is "admin" and the password is "admin".

		edb.example.org
		ou=edb
		cn=admin
		password = admin
	
3. Test the connection to LDAP on the same server it was installed using the following command.  If ldapsearch does not exist, then install **openlap-clients** for Red Hat-based distributions or **ldap-utils** for Debian-based distributions.

		ldapsearch -H ldap://localhost -W -U admin -b "cn=admin,dc=edb,dc=example,dc=org"
		
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
		
## Install and Configure ldap2pg
1. Log onto the node you wish to run the ldap2pg application.

2.  Create a user that has a login to the PostgreSQL database as an unprivileged role with CREATEDB and CREATEROLE privileges, for example ldap2pguser.  As stated in the prerequisites ensure that the node running ldap2pg has access to the PostgreSQL database.

3. Download and install [ldap2pg](https://ldap2pg.readthedocs.io/en/latest/) as an administrator. 

4. **Configure PostgreSQL Connection Settings**  If only one PostgreSQL instance database will be synchronized you may set the global environment variables for the user who is performing the synchronization. Replace the following variables to match your environment. Alternatively, in step #7 below you may include them in the synchronization scripts if multiple PostgreSQL instances and YAML files are needed.

		export PGUSER=ldap2pguser
		export PGPASSWORD='<password>'
		export PGDATABASE=postgres
		export PGPORT=5444
	
4. **Create LDAP Connection Config File** Create an LDAP configuration file.  You may create the LDAP configuration file anywhere by setting the environment variable:  **export LDAPCONF=/path/to/your/ldap.conf**  <br>  
If you do not, ldap2pg will look for an LDAP configuration file for connection information in the following order:  
	
		path=/etc/ldap/ldap.conf
		path=/var/lib/edb-as/ldaprc 
		path=/var/lib/edb-as/.ldaprc 
		path=/var/lib/edb-as/ldap2pg/ldaprc  
		path=/path/to/your/ldap.conf 
		
5. **Configure LDAP Connection Config File** Configure the contents of the LDAP configuration file where ldap2pg will retrieve the connection information from.  The key take away here is you must use **PASSWORD** token to indicate the password for the LDAP authentication.
    
		BASE	  dc=edb,dc=example,dc=org
		URI	  ldap://ldap.enterprisedb.com
		BINDDN    cn=admin,dc=edb,dc=example,dc=org
		PASSWORD  admin

6. Copy all files from this project's repository folder to a folder on your ldap2pg node:

		/ldap2pg/ldap2pg-config
		
7. Update the environment variables in each of the SH scripts to match your environment or delete them if you are using the global settings defined in step #3.  An example of the contents of one of the scripts is the following:

		#!/bin/bash
		
		export PGUSER=ldap2pguser
		export PGPASSWORD='<password>'
		export PGDATABASE=postgres
		export PGPORT=5444
		
		ldap2pg --config ldap2pg.yml

8. **Configure the ldap2pg.yml File** The ldap2pg.yml defines the scope and search criterion for syncing the LDAP groups and users to the PostgreSQL databases.  The ldap2pg.yml may be used as is, except for the postgres section.  List those roles you do not want to be synced separated by commas, list the databases that pertain to this synchronization separated by commas, and list the schemas that pertain to the synchronization.

		postgres:
		  roles_blacklist_query: [admin,PostgreSQL, pg_*,bdr*,replication*,barman*,test*,aq*,streaming*,pgd*]
		  databases_query: [PostgreSQL]
		  schemas_query: [public]

9. Test the connection of ldap2pg by entering the following command.

		ldap2pg --config ldapp2pg/ldap2pg.yml

10. An example output that indicates a successful connection to the PostgreSQL database and LDAP instance is the following:

		06:14:50 INFO   Starting ldap2pg                                 version=v6.0 runtime=go1.20.5 commit=023e6933
		06:14:50 INFO   Using YAML configuration file.                   path=ldap2pg.yml
		06:14:50 INFO   Running as superuser.                            user=ldap2pguser super=false server="PostgreSQL 15.6" cluster=dc-pgd1 database=postgres
		06:14:50 INFO   Connected to LDAP directory.                     uri=ldap://example.com authzid="dn:cn=admin,dc=edb,dc=example,dc=org"




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

### View Current Roles and Users in PostgreSQL Database
Obtain a database session to the PostgreSQL database you are syncronizing with.  Perform the following steps to view the current set of roles and users.
	
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
	
1. Run the Validate Config.  Discuss how it verifies connection to ldap then to PostgreSQL, then finally performing the synchronization listing all the tasks it will perform
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
This removes the new users and groups from PostgreSQL database synced with ldap so you can run the demo again.

	bdrdb=# \i  psql-scripts/revoke-priv-role.sql




