#!/usr/bin/env bash

# Starting variables

STARTDIR=$(pwd)
BUILDDIR=/tmp/$USER-pg-build
INSTALLDIR=$HOME/pgsql
PGVERSION=12.15
SOURCEPKG=postgresql-$PGVERSION.tar.bz2
CONFIGUREOPTIONS="--with-openssl" # openssl just in case
# if you need additional configure options, add them above separated by space

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

# define PROFILEFILE

SHELLNAME=$(basename "$SHELL")
if [ "x$2" != "x" ]; then
PROFILEFILE=$HOME/$2
touch "$PROFILEFILE"
# for example: .bash_profile, .profile or I_want_to_see_what_would_be_added
echo "Using $2 to save environment variables."
elif [ "$SHELLNAME" = "bash" ]; then
PROFILEFILE=$HOME/.bashrc
echo "You are currently using bash as your shell, so defaulting to .bashrc for environment variables."
elif [ "$SHELLNAME" = "zsh" ]; then
PROFILEFILE=$HOME/.zshrc
echo "You are currently using zsh as your shell, so defaulting to .zshrc for environment variables."
elif [ "$SHELLNAME" = "csh" ] || [ "$SHELLNAME" = "tcsh" ]; then
PROFILEFILE=$HOME/pg-shellvariables
echo "This script does not automatically add variables with csh syntax to your shell configuration."
echo "Please add manually variables from $PROFILEFILE to your .cshrc using csh syntax."
else
PROFILEFILE=$HOME/.shrc
echo "Defaulting to .shrc for environment variables, if this is incorrect, please copy these manually to correct file."
fi

echo "
Building in $BUILDDIR
Installing to $INSTALLDIR
Adding environment variables to $PROFILEFILE

Build should take about 5 minutes."
sleep 5

mkdir -p "$BUILDDIR"

if [ "$1" = "install" ]; then
cd /tmp || exit
curl -O https://ftp.postgresql.org/pub/source/v$PGVERSION/$SOURCEPKG
PGFILE=$(realpath $SOURCEPKG)
cd "$BUILDDIR" || exit
elif [ -f "$1" ]; then
PGFILE=$(realpath "$1")
cd "$BUILDDIR" || exit
else
echo "
no valid command or file as first parameter.
"
rmdir "$BUILDDIR"
exit 1
fi


# build and install

SOURCEDIR=$(basename "$PGFILE" .tar.bz2)

tar -xjf "$PGFILE"
cd "$SOURCEDIR" || exit
./configure --prefix="$INSTALLDIR" $CONFIGUREOPTIONS
if [ $? -gt 0 ];
then
  exit 1
fi
make
if [ $? -gt 0 ];
then
  exit 1
fi
make install-strip
if [ $? -gt 0 ];
then
  exit 1
fi

# update profile file
env_vars="export LD_LIBRARY_PATH=$INSTALLDIR/lib
export PATH=$INSTALLDIR/bin:\$PATH
export PGHOST=$INSTALLDIR/sock
export PGDATA=$INSTALLDIR/data"

if [ -f "$PROFILEFILE" ]; then
if grep -q "$INSTALLDIR" "$PROFILEFILE" 2>/dev/null; then
echo "
$PROFILEFILE not updated, $INSTALLDIR is already mentioned there, so assuming this is reinstall and it is up to date.
"
else
echo "$env_vars" >> "$PROFILEFILE"
echo "
Added environment variables to $PROFILEFILE
"
fi
else
echo "$PROFILEFILE does not exist!"
echo "
Added environment variables to $INSTALLDIR/README.environment, copy these manually to correct location.
"
fi

echo "$env_vars" >> "$INSTALLDIR/README.environment"

# modify default config to use only sockets

mv "$INSTALLDIR/share/postgresql.conf.sample" "$INSTALLDIR/share/postgresql.conf.sample.orig"
sed -e "s|#listen_addresses = 'localhost'|listen_addresses = ''|" \
-e "s|#unix_socket_directories = '/tmp'|unix_socket_directories = '$INSTALLDIR/sock'|" \
-e 's|#unix_socket_permissions = 0777|unix_socket_permissions = 0700|' \
< "$INSTALLDIR/share/postgresql.conf.sample.orig" > "$INSTALLDIR/share/postgresql.conf.sample"

mkdir "$INSTALLDIR/sock"
chmod 0700 "$INSTALLDIR/sock"

# move to where we started and clean up

cd "$STARTDIR" || exit
rm -R "$BUILDDIR"

# initdb and createdb

echo "Creating database, please wait."

"$INSTALLDIR/bin/initdb" --auth-local=trust --auth-host=reject -D "$INSTALLDIR/data" > /dev/null
"$INSTALLDIR/bin/pg_ctl" -s -D "$INSTALLDIR/data" -l "$INSTALLDIR/createdb-logfile" start
"$INSTALLDIR/bin/createdb" -h "$INSTALLDIR/sock" "$USER"
"$INSTALLDIR/bin/pg_ctl" -s -D "$INSTALLDIR/data" stop

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

$INSTALLDIR/bin/postgres -D $INSTALLDIR/data" > "$INSTALLDIR/bin/start-pg.sh"
chmod u+x "$INSTALLDIR/bin/start-pg.sh"

# create file with variables

echo "
data directory (PGDATA): $INSTALLDIR/data
socket directory (PGHOST): $INSTALLDIR/sock
database name: $USER

" > "$INSTALLDIR/README.variables"

# create file with uninstall instructions

echo "
1) If you want to save your database contents, move $INSTALLDIR/data
   out of $INSTALLDIR.
2) Delete entire $INSTALLDIR.
3) Remove lines mentioning pgsql with LD_LIBRARY_PATH, PATH, PGHOST and
   PGDATA at or near the end of your $PROFILEFILE 
   (or where ever you have added them manually)

" > "$INSTALLDIR/README.uninstall"
