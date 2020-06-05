# local-pg

This script is meant for installing PostgreSQL for personal development use without admin privileges when using University of Helsinki Department of Computer Science lab computers (and fuksilappari) running Cubbli linux.
OS (Cubbli) in these systems is based on Ubuntu, so this script probably works with Ubuntu too, and possibly other Linux distributions.

If you have admin privileges, installing PostgreSQL using your OS package manager or in a container is better alternative. If you intend to run PostgreSQL in production, do not use this script, there is unlikely to be security updates.


## Requirements

See [PostgreSQL documentation](https://www.postgresql.org/docs/12/install-requirements.html).

- GNU Make 3.80
- gcc or other compiler supporting C99
- tar
- bzip2
- readline
- zlib
- openssl

If you are using department computers, all of these should be installed already.

You will need access to directory /tmp for the build process.

Installed size without any data in database is about 92M.


## Usage

Basic usage: `bash pg-install.sh FILE` where FILE is .tar.bz2 packaged [source code of PostgreSQL](https://www.postgresql.org/ftp/source/).

For example, assuming you have file postgresql-12.3.tar.bz2 with PostgreSQL source code in your Downloads directory:
`bash pg-install.sh ~/Downloads/postgresql-12.3.tar.bz2`

Alternatively, you can use word `install` instead of filename. In this case, script will try to download source code for version 12.3 using curl:
`bash pg-install.sh install`

Part of the script will add various environment variables to your .bashrc. You can override this by giving second parameter, for example:
`bash pg-install.sh install .bash_profile`


## Using installed PostgreSQL

Script will install PostgreSQL and your database in to your home directory, and add necessary environment variables in to your .bashrc. Installed configuration will only accept connections from you using unix socket.

Since lab computers are shared, please do not leave your database running in the background. For your convenience, there is start-pg.sh script which will start PostgreSQL in your terminal on the foreground, so you (hopefully) won't forget to stop running your database when you leave computer.


## Uninstalling

- Remove directory pgsql, including all content (in your home directory).
- Remove lines mentioning pgsql with LD_LIBRARY_PATH, PATH, PGHOST and PGDATA at the end of your .bashrc.


## Caveats

There is practically no error checking. If build or something else fails, you are left to figure out what went wrong by yourself.

If you have problems with requirements, see PostgreSQL documentation about possible configure options for requirements (link above), and modify variable CONFIGUREOPTIONS in the start of the script as needed.
