# Simple Certificate Authority management scripts

Creating a working and compliant Certification Authority was always a difficult task. On the other hand many IT
specialists and developers need to use certificates in their work to test things before they go to the production
status. Using official certificates is not always a feasible solution because it may be expensive or cumbersome. Many
people created more accessible solutions but non of them ever was good enough for me. That's why I have created
the `sk-*` certificate authority management set of **Bash** scripts.

The scripts were designed to be machine and architecture independed with a few requirements:

* Working **Bash** shell
* GNU utilities: `grep`, `openssl`, `tar`, `gzip`, `gpg`, etc.
* Publicly available hosting space to store Certification Authority root certificate and certificate revocation list.

Once initialized, the CA will operate using a local folder as a storage and will allow you to:

* Issue server certificates
* Issue end-user certificates
* Revoke certificates
* Pack certificates into portable PKCS#12 file format
* Backup the CA database

I hope you will find the scripts useful.

The author,  
Slawomir Koszewski

## Installation

Download the latest release bundle from [GitHub Page](https://github.com/skoszewski/sk-ca-scripts/).

The following script will download and extract file to the current directory:

```shell
curl -s -L https://github.com/skoszewski/sk-ca-scripts/archive/refs/tags/v1.2.2.tar.gz | tar -x -v -z -f -
```

and the following will extract the file to the pre-created directory `/usr/local/share/sk-ca`:

```shell
curl -s -L https://github.com/skoszewski/sk-ca-scripts/archive/refs/tags/v1.2.2.tar.gz | tar -x -v -z -C /usr/local/share/sk-ca --strip-components=1 -f -
```

## Create a CA

Find a place to store scripts. Download the **tar** file and unpack them.

Initialize the folder structure with the following command:

```
<path to the scripts folder>/sk-init-ca <path to the CA folder>
```

> NOTE: You can specify en empty folder or a non-existing location. The new folder will be created.

Review the created `openssl` configuration file and modify it based on your requirements.

Source the shell enviroment variables:

```
. <path to the ca folder>/env.sh
```

The `env.sh` file will set up the required shell variables and modify your `PATH`. You will no longer need to use full
path to run scripts.

Run the `sk-make-ca` script to finalize certificate authority file structure creation.

Use `-s` or `--subca` parameter to `sk-make-ca` to create a subordinate CA instead of root CA. The certificate signing
request will be created instead of self-signed certificate. Send the request to the signing Certificate Authority and
place the issued certificate in `certs` directory. Keep the same name as the request file has. Replace the `.req` suffix
with the `.pem`.

The CA will hold private keys in `private` folder and certificates in `certs`. You will also be able to find
automatically generated passwords for PKCS#12 files in the `private` folder. These are clear text files only protected
by file system permissions. PKCS#12 files will also be stored in `certs` folder. These files are encrypted and do not
need to be protected by filesystem.

> WARNING: Do not modify files `index.txt`, `serial`, `private/<ca_name>-key.pem` and `newcerts` folder by hand unless
> you know what you are doing.

## Easy certificate issuance

Create a server certificate:

```
sk-new-server-cert <name> <dns name> [<san name>] [<san name>] [<san name>] ...
```

* `name` - the configuration name - keep it simple and use only letters and dashes.
* `dns name` - the primary DNS name for the host. It will be used as **Common Name**.
* `san name` - secondary DNS names or IP addresses

Create an end-user certificate:

```
sk-new-user-cert <name> <full name> <email>
```

* `name` - the configuration name - same as above.
* `full name` - the **Common Name** for the certificate. Usually the certificate owner full name.
* `email` - the certificate owner e-mail address.

The server certificate will be usable as both server and client authentication. It may be used as a web or mail server
certificate as well as router certificate (VPN). The client certificate can be used as client identification, e-mail
signing or code signing certificate.

If you need more refined certificate type, you have to edit the `<ca_name>.conf` file.

Simplified issuance scripts automatically create a configuration file, a certificate signing request
and sign the request. If you need more control over the process, follow the guide in the next section.

## Regular certificate creation

Use the `sk-make-conf` script to create a configurationf file:

```
sk-make-conf <name> <common name>
```

A file named `<name>.conf` will be created from the template in the `config` subdirectory.

A sample configuration file:

```
[ req ]
distinguished_name = req_dn
prompt = no

[ req_dn ]
CN                 = test.example.com
#OU                 = Organizational Unit Name
#O                  = Optional organization name
#L                  = Optional city name
#ST                 = State or Province
#C                  = Optional country code, e.g. PL
```

Remove `#` characters to uncomment a line and define certificate attribute.
Add `[ req_ext ]` section to declare subject alternative names, e.g.:

```
[ req_exts ]
subjectAltName = DNS:test.example.com, DNS:www.example.com, IP:192.168.1.1
```

Use `sk-make-req` scripti

## Signing certificate requests

You can use `sk-sign-req` script to directly sign requests created outside of the CA.

The script takes two arguments:

```
sk-sign-req <configuration_name> <server|client|subca>
```

or

```
sk-sign-req <path_to_the_request_file> <server|client|subca>
```

> NOTE: The request file must be in the PEM format.

## Management operations

Certificates may be revoked using `sk-revoke-cert` script.

```
sk-revoke-cert <name>
```

Create a revocation list using the `sk-make-crl` script. The CRL will be placed in the
`crl` subdirectory of CA data directory. Upload the CRL to the distribution
point specified in the CA initialization phase. You can always check what CRL URL is in the
CA configuration file.

Create a PKCS#12 file.

```
sk-make-pkcs12 <name>
```

> NOTE: You will be asked if you want to provide your own password to protect private key data. If you answer no or do
> not provide any input the script will generate random 12-character password and store it along side with the private
> key. The password will be stored in clear text and protected only by file system permissions (read-write only by owner).

If you want to change the default certificate options and attributes you are free to modify the `ca.conf` configuration
file or genrated configuration files stored in `configs` folder. The following scripts are meant to be used in advanced
scenarios:

* `sk-make-conf` - create a server certificate config.
* `sk-make-user-conf` - create an end-user certificate config.
* `sk-make-req` - create a certificate request file. You can either use it or send to another CA for signing.
* `sk-sign-req` - sign a certificate request. The CA policy will allow any attributes - there are no restrictions, so
  you can sign requests created by you, automatically generated by software tools or appliances.
* `sk-make-crl` - create a CRL file (in the `crl` folder).
* `sk-make-dh` - create a Diffie-Hellman key. It is needed by the OpenVPN server setup.
* `sk-backup-ca` - make a backup of the CA database. The backup file will be stored in `backups` folder and encrypted.
* `sk-restore-ca` - restore a CA backup.

## Backups

It is obvious that Certification Authority database must be kept in a safe place and regularly backed up. Test CAs may
seem less important, but sometimes recreating the CA and reissuing a lot of development certificates will be time
consuming. To avoid that tedious work - let's do backups.

The script suite has two scripts related to data recovery: `sk-backup-ca` and `sk-restore-ca`. I have decided to use
common GNU utilities: `tar` and `gpg`. The backup script will capture the entire CA database folder and encrypt it with
a key using **AES-256** alghoritm. The backups are stored in `backups` subfolder and you have to copy them to a safe
place - a cloud storage for example. The backup encryption key is stored in a text file located in the CA root folder.
Store it in another safe place. It will be required to restore files.

`sk-backup-ca` does not take any arguments. Just source the CA shell environment and run the script.

`sk-restore-ca` do to require CA shell environment, because it will not exist before the files are restored. Run the
script with three arguments.

```
sk-restore-ca <path-to-backup-file> <path-to-secret-key-file> <path-to-new-ca-root-folder>
```

Copy the old secret key file to the new root CA folder if you want to reuse it.

## Upload the backup to the Azure BLOB storage

Use provided `sk-upload-to-azure` or `sk-upload-to-azure.ps1` scripts to upload the backup file to Azure blob storage.

Run the Bash script:

```
sk-upload-to-azure <path-to-backup-file> <resource group> <storage account> <container>
```

or set shell environment variables: `STORAGE_ACCOUNT`, `CONTAINER` and `SAS_TOKEN` and run it with less parameters:

```
sk-upload-to-azure <path-to-backup-file>
```

Alternatively, use PowerShell

```powershell
sk-upload-to-azure.ps1 -Path <string> -ResourceGroup <string> -StorageAccount <string> -Container <string>
```
