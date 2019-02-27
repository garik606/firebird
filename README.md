# docker Firebird

## Supported tags and respective `Dockerfile` links

[`2.5-sc`, `2.5.8-sc` (*2.5-sc/Dockerfile*)](https://github.com/garik606/firebird4/blob/2.5-sc/Dockerfile)

[`2.5-ss`, `2.5.8-ss` (*2.5-ss/Dockerfile*)](https://github.com/garik606/firebird4/blob/2.5-ss/Dockerfile)

[`3.0`, `3.0.4` `latest` (*Dockerfile*)](https://github.com/garik606/firebird4/blob/master/Dockerfile)

[`4.0`, `4.0.0-beta1` `beta1` (*4.beta1/Dockerfile*)](https://github.com/garik606/firebird4/blob/4.beta1-jessie/Dockerfile)


## Default password for `sysdba`
The default password for `sysdba` is randomly generated when you first launch the container, 
look in the docker log for your container or check `/firebird/etc/SYSDBA.password`.
Alternatively you may pass the environment variable ISC_PASSWORD to set the default password.

## Description
This is a Firebird SQL Database container.

## Default Login information
Username: SYSDBA
Password is either set by `ISC_PASSWORD` or randomized

## Environment Variables:
### `TZ`
TimeZone. (i.e. America/Chicago)

### `ISC_PASSWORD`
Default `sysdba` user password, if left blank a random 20 character password will be set instead.
The password used will be placed in `/firebird/etc/SYSDBA.password`.
If a random password is generated then it will be in the log for the container.

### `FIREBIRD_DATABASE`
If this is set then a database will be created with this name under the `/firebird/data` volume with the 'UTF8'
default character set and if `FIREBIRD_USER` is also set then `FIREBIRD_USER` will be given ownership.

### `FIREBIRD_USER`
This user will be created and given ownership of `FIREBIRD_DATABASE`.
This variable is only used if `FIREBIRD_DATABASE` is also set.

### `FIREBIRD_PASSWORD`
The password for `FIREBIRD_USER`, if left blank a random 20 character password will be set instead.
If a random password is generated then it will be in the log for the container.

### `EnableLegacyClientAuth`

If this is set to true then when launching without an existing /firebird/etc folder this will cause the newly created firebird.conf to have 
the following defaults:
```
AuthServer = Legacy_Auth, Srp, Win_Sspi 
AuthClient = Legacy_Auth, Srp, Win_Sspi 
UserManager = Legacy_UserManager, Srp 
WireCrypt = enabled 
```
This will allow legacy clients to connect and authenticate.

### `EnableWireCrypt`

If this is set to true then when launching without an existing /firebird/etc folder this will cause the newly created firebird.conf to have
`WireCrypt = enabled` to allow compatibility with Jaybird 3

### `<VARIABLE>_FILE`
If set to the path to a file then the named variable minus the _FILE portion will contain the contents of that file.
This is useful for using docker secrets to manage your password.
This applies to all variables except `TZ`

## Server Architectures
At the moment only the "Super Classic" and "Super Server" architectures are available.

### SC
Super Classic.
### SS
Super Server.
### CS
Classic Server.

## Volumes:

### `/firebird`
This single volume supercedes all of the old volumes with most of the old volumes existing as subdirectories under `/firebird`

#### `/firebird/data`
Default location to put database files

#### `/firebird/system`
security database DIR

#### `/firebird/etc`
config files DIR
message files DIR

#### `/firebird/log`
log files DIR

### Read Only root filesystem
For some users they may prefer to run the filesystem in read only mode for additional security.
These volumes would need to be created rw in order to do this.

#### `/var/firebird/run`
This volume does not actually exist by default but you may want to create it if you wish to use a `read only` root filesystem
guardian lock DIR

#### `/tmp`
This volume does not actually exist by default but you may want to create it if you wish to use a `read only` root filesystem
Database lock directory

## Exposes: 
### 3050/tcp

## Health Check
I have now added [HEALTHCHECK support](https://docs.docker.com/engine/reference/builder/#healthcheck) to the image. By default it uses nc to check port 3050.
If you would like it to perform a more thorough check then you can create `/firebird/etc/docker-healthcheck.conf`
If you add `HC_USER` `HC_PASS` and `HC_DB` to that file then the healthcheck will attempt a simple query against the specified database to determine server status.

Example `docker-healthcheck.conf`:
```
HC_USER=SYSDBA
HC_PASS=masterkey
HC_DB=employee.fdb
```

## Events
Please note for events to work properly you must either configure RemoteAuxPort and forward it with -p using a direct mapping where both sides internal and external use the same port or use --net=host to allow the random port mapping to work.
see: http://www.firebirdfaq.org/faq53/ for more information on event port mapping.
