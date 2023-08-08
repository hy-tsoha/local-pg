# local-pg

This script is meant for installing PostgreSQL for personal development use without admin privileges when using University of Helsinki Department of Computer Science lab computers (and fuksilappari) running Cubbli linux.
OS (Cubbli) in these systems is based on Ubuntu, so this script probably works with Ubuntu too, and possibly other Linux distributions.

If you have admin privileges, installing PostgreSQL using your OS package manager or in a container is probably better alternative. Even in these cases, benefit of this script would be that it configures PostgreSQL to only allow connections through unix socket, so your development database is not exposed to network. However, you can yourself configure any PostgreSQL installation similarly.

If you intend to run PostgreSQL in production, do not use this script, there is unlikely to be security updates.


## Requirements

See [PostgreSQL documentation](https://www.postgresql.org/docs/12/install-requirements.html) for more detailed description of installation requirements.

Your computer needs to have following tools and libraries installed:

- GNU Make 3.80
- gcc or other compiler supporting C99
- tar
- bzip2
- readline
- zlib
- openssl

If you are using department computers, all of these requirements should be installed already. If you are using some other computer, you need to make sure these are installed.

You will need access to directory /tmp for the build process.

Installed size without any data in database is about 92M.


## Usage

Basic usage: `bash pg-install.sh FILE` where FILE is .tar.bz2 packaged [source code of PostgreSQL](https://www.postgresql.org/ftp/source/).

For example, assuming you have file postgresql-12.15.tar.bz2 with PostgreSQL source code in your Downloads directory:
`bash pg-install.sh ~/Downloads/postgresql-12.15.tar.bz2`

Alternatively, you can use word `install` instead of filename. In this case, script will try to download source code for version 12.15 using curl:
`bash pg-install.sh install`

Part of the script will add various environment variables to your .bashrc. Normally above example commands should be fine, but if you need to override where environment variable changes are saved you can do so by giving second parameter, for example:
`bash pg-install.sh install .bash_profile`


## Using installed PostgreSQL

Script will install PostgreSQL and your database in to your home directory, and add necessary environment variables in to your .bashrc. Installed configuration will only accept connections from you using unix socket in ~/pgsql/sock directory.

Since lab computers are shared, please do not leave your database running in the background. For your convenience, there is `start-pg.sh` script which will start PostgreSQL in your terminal on the foreground, so you (hopefully) won't forget to stop running your database when you leave computer. Directory with the script should be added to your PATH variable, so you can run it without writing full path. After installation, you need to re-open your terminal window or run `source ~/.bashrc` for the command `start-pg.sh` to work. Note that you will need to keep this script running as long as you want to use database.

When you want to stop PostgreSQL, stop it with ctrl-c. Closing terminal will not stop PostgreSQL, only detach it to background. If you do this, you need to stop PostgreSQL manually. For your convenience, oneliner `kill $(ps x|grep pgsql/bin/postgres|grep -v grep|awk '{print $1}')` may work.

In code: If everything went right and you are using recent version (>1.3.2) of SQLAlchemy, you can now use `postgresql+psycopg2://` as your connection string.


## Uninstalling

- Uninstallation instructions are in pgsql/README.uninstall


## Caveats

There is practically no error checking. If build or something else fails, you are left to figure out what went wrong by yourself.

If you have problems with requirements, see PostgreSQL documentation about possible configure options for requirements (link above), and modify variable CONFIGUREOPTIONS at the start of the script as needed.
