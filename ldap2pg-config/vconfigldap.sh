#!/bin/bash

export PGUSER=ldap2pguser
export PGPASSWORD='<password>'
export PGDATABASE=postgres
export PGPORT=5444

ldap2pg -v --config ldap2pg.yml