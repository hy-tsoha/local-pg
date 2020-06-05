#!/usr/bin/env bash

# Starting variables

STARTDIR=$(pwd)
BUILDDIR=/tmp/$USER-pg-build
HOMEDIR=$HOME
INSTALLDIR=$HOMEDIR/pgsql
PROFILEFILE=$HOMEDIR/.bashrc
USERNAME=$USER
PGVERSION=12.3
SOURCEPKG=postgresql-$PGVERSION.tar.bz2

if [ -z "$1" ]; then
echo "
First argument should be filename for bzip2 packaged (.tar.bz2) source 
code of PostgreSQL. You can download source code from: 
  https://www.postgresql.org/ftp/source/

If you use word 'install' instead of filename, this script will try 
to automatically download version $PGVERSION of PostgreSQL source code.
If you give second parameter, it will be used as file name where to 
save environment variables instead of .bashrc.

for example:
    $0 Downloads/$SOURCEPKG"
exit 1
fi

# modify PROFILEFILE if there is second parameter

if [ "x$2" != "x" ]; then
PROFILEFILE=$HOMEDIR/$2
# for example: .bash_profile, .profile or I_want_to_see_what_would_be_added
fi

echo "
Building in $BUILDDIR
Installing to $INSTALLDIR
Adding environment variables to $PROFILEFILE

Build should take about 5 minutes."
sleep 5

mkdir -p $BUILDDIR

if [ "$1" = "install" ]; then
cd $BUILDDIR
curl -O https://ftp.postgresql.org/pub/source/v$PGVERSION/$SOURCEPKG
PGFILE=$(realpath $SOURCEPKG)
elif [ -f "$1" ]; then
PGFILE=$(realpath $1)
cd $BUILDDIR
else
echo "
no valid command or file as first parameter.
"
rmdir $BUILDDIR
exit 1
fi


# build and install

SOURCEDIR=$(basename $PGFILE .tar.bz2)

tar -xvjf $PGFILE
cd $SOURCEDIR
./configure --prefix=$INSTALLDIR --with-openssl # openssl just in case
make
make install-strip

# update .bash_profile

grep -q $INSTALLDIR $PROFILEFILE 2>/dev/null
if [ $? -gt 0 ]; then
echo "LD_LIBRARY_PATH=$INSTALLDIR/lib
export LD_LIBRARY_PATH
PATH=$INSTALLDIR/bin:$PATH
export PATH
MANPATH=$INSTALLDIR/share/man:$MANPATH
export MANPATH
PGHOST=$INSTALLDIR/sock
export PGHOST
PGDATA=$INSTALLDIR/data
export PGDATA" >> $PROFILEFILE
echo "
Added environment variables to $PROFILEFILE
"
else
echo "
$PROFILEFILE not updated, $INSTALLDIR is already mentioned there, so assuming this is reinstall and it is up to date.
"
fi

# modify default config to use only sockets

mv $INSTALLDIR/share/postgresql.conf.sample $INSTALLDIR/share/postgresql.conf.sample.orig
sed -e "s|#listen_addresses = 'localhost'|listen_addresses = ''|" \
-e "s|#unix_socket_directories = '/tmp'|unix_socket_directories = '$INSTALLDIR/sock'|" \
-e 's|#unix_socket_permissions = 0777|unix_socket_permissions = 0700|' \
< $INSTALLDIR/share/postgresql.conf.sample.orig > $INSTALLDIR/share/postgresql.conf.sample

mkdir $INSTALLDIR/sock
chmod 0700 $INSTALLDIR/sock

# move to where we started and clean up

cd $STARTDIR
rm -R $BUILDDIR

# initdb and createdb

echo "Creating database, please wait."

$INSTALLDIR/bin/initdb --auth-local=trust --auth-host=reject -D $INSTALLDIR/data > /dev/null
$INSTALLDIR/bin/pg_ctl -s -D $INSTALLDIR/data -l $INSTALLDIR/createdb-logfile start
$INSTALLDIR/bin/createdb -h $INSTALLDIR/sock $USERNAME
$INSTALLDIR/bin/pg_ctl -s -D $INSTALLDIR/data stop

echo "
******
You may need to start new terminal (or relogin) for environment variables 
to update.

Use command start-pg.sh to start database, ctrl-c to stop it.

If you are running this with computer which is in private use (ie. not a lab 
computer), you could also start and stop database in the background using 
pg_ctl utility, refer to documentation for details.

When it is running, you can connect to database in different terminal with 
command:
    psql

When you need to connect to database from code, use socket in 
$INSTALLDIR/sock 
with default database name and no need to give username or password. Please 
do not hardcode this into your code, this connection will only work for you.

******"

# create startup script mentioned above

echo "#!/usr/bin/env bash

$INSTALLDIR/bin/postgres -D $INSTALLDIR/data" > $INSTALLDIR/bin/start-pg.sh
chmod u+x $INSTALLDIR/bin/start-pg.sh

# create file with variables

echo "
data directory (PGDATA): $INSTALLDIR/data
socket directory (PGHOST): $INSTALLDIR/sock
database name: $USERNAME

" > $INSTALLDIR/README.variables
