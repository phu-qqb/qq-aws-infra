# QuantumQb infrastructure usage

## Where to obtain access data

Secrets required to connect to different kind resources in infrastructure are kept in s3 "access-bits" bucket under "keys" folder. They are just for reference purpose only, changing them does not affect configured accounts at instances and vice-versa. So to effectively change this access data please refer to corresponding section of this reference. Upon
setting new secrets etc. you can update these info in the access-bits values for you convenience. To read and update data you can use AWS web console or corresponding CLI command being authenticated as user with corresponding rights at AWS.

Read data with AWS CLI (will be put in the file):
```
aws s3 cp s3://access-bits/keys/<key_name> <file_name_corresponding_to_key_or_whatever> --sse aws:kms
```
Put data to key:
```
aws s3 cp  <name_of_the_file_with_data_to_store>  s3://access-bits/keys/<key_name>--sse aws:kms
```

There we have the following types of keys to refer to:
- xxx_secret: passwords for windows workstations user from AD where xxx is username, they are used as local users with the same passwords at GPU server instance
- xxx_gpu_server(.pub): key pairs to access to GPU server instance by SSH
- sample_ssh_profile: sample ~/.ssh/config part to simplify ssh login from workspace to GPU server
- db_connect_xxx: example to check connection to DBs with Invoke-Sqlcmd applet from PowerShell with concrete resource and user data, where xxx defines db and connection type
- db_prod_admin, db_qa_admin: SQL Server passwords for "admin" user

## Workspaces, File server, Active Directory, Trading Application instance

### Access to workspaces

To connect to workspace you can use AWS GUI client "Amazon Workspaces" available here: https://clients.amazonworkspaces.com/

All workspaces in these infrastructure available under the code: **wslhr+CPJ9NV**

We have the following users preconfigured:
- "Trusted" group:
  - phu
  - afr
  - agi
- "Server" group:
  - trd
- "Guest" group:
  - est

To connect to user desktop use its name and password from the S3 bucket mentioned above with the following pattern: "\<username\>_secret". N.B. Don't add the domain name to the user name.

### User instances connectivity

Every station has connection to:

- Trading server station via RDS
- Production and QA database servers
- Via RDS proxy to Production DB server
- File Server
- GPU Linux server via SSH
- Internet access via NAT

### User instances specification (Trusted group)

- Power Pro instance type
- Based on Windows 10 server 2022
- WSP access protocol
- 8 vCPUs
- 32Gb RAM
- 80Gb root partition
- 50Gb user partition
- Auto-stop in 4 hours

### Trading application server instance

Trading server has the same connectivity as trusted user stations but designated to run as production server. It has its own designated user in AD as well as other users. Trusted users can connect to it using preinstalled Windows RDP client. There we use "WSAMZN-1NJL3EBR.stable.qq.infra" computer name and user name with NetBios domain name, for example: "STABLEQQINFRA\phu"
To define users that are able to connect via RDP we can login into Trading Application Server (as domain user or via RDP) and use "System > Remote Desktop > User Accounts" option.

It's specifications are:

- General Purpose 4xlarge instance type
- Based on Windows 10 server 2022
- WSP access protocol
- 16 vCPUs
- 64Gb RAM
- 175Gb root partition
- 100Gb user partition
- No auto-stop

### Manage AD users

Trading application server has "Active Directory Administrative Center" feature from Windows distribution for Admin user. We can login into "trd" instance under "STABLEQQINFRA\Admin" name to run this utility to enable/disable users, reset user passwords, change login names and edit other profile data.

### Shared folder

Every trusted admin user has access to File Server shared folder already pre-mounted as disk Z:
You can unmount it using:
```shell
 net use Z: /delete
```
or mount it again using:
```shell
 net use Z: \\amznfsx7wpvxypq.stable.qq.infra\share
```
options.

This folder also used to store roaming user profiles that are synced during their logon/logoff under "profiles" folder.
File server is configured to have 2Tb space and daily backups.

### Guest station specifications:

- Standard instance type
- Based on Windows 10 server 2022
- WSP access protocol
- 2 vCPUs
- 4Gb RAM
- 80Gb root partition
- 50Gb user partition
- Auto-stop in 1 hour

## Database

### Database connection

We can connect to DB using connection parameters specified in db_connect_xxx values in S3 "access-bits/keys" bucket.
- db_connect_prod_direct - Trading database
- db_connect_prod_proxy - recommended for production use as optimized connection manager.
- db_connect_qa_direct - ResearchLab database

### Production DB specifications

- SQL Server Standard edition 2022 / 16.00.4150.1.v1
- db.m5.xlarge instance type
- 4 vCPUs
- 16Gb RAM
- General Purpose SSD (gp3)
- Allocated storage 100Gb
- Multi-zone
- Autobackup with 7 day retention
- Proxy

### QA DB specifications

- SQL Server Express edition 2022 / 16.00.4175.1.v1
- db.t3.medium instance type
- 2 vCPUs
- 4Gb RAM
- General Purpose SSD (gp3)
- Allocated storage 100Gb
- Single-zone
- Multi-zone
- Autobackup with 7 day retention

## GPU server

We can access this Linux instance via SSH, keys and configurations already preconfigured for trusted and admin users, so its enough to use this command to connect:
```shell
ssh gpu-server
```
in order to login into it under your username. All ssh users are sudoers.


