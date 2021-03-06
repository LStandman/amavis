#! /bin/sh -e

#Setting up amavisd-new to run in a chroot jail
#==============================================
#2003-03, Mark Martinec
#Last updated: 2005-08-11
#
#Preparing system services to run under chroot is not for
#inexperienced Unix administrators!
#
#This is not an automated script, but rather a checklist, guidelines
#and ideas to help set up an environment in which amavisd-new and
#its external utilities can run in a Unix chroot cage (jail) to reduce
#the possible security threats and protect the rest of the system.
#
#Details vary greatly from one Unix system to another. The following
#examples are based on FreeBSD and Linux, but should be useful for
#other Unix systems. Some of the paths are likely to be different.
#
#The following is based on setting a SMTP-based amavisd-new (e.g. to be
#use with Postfix or dual-MTA setup). It was tried out with all external
#decoding programs, with SpamAssassin and with the following virus scanners:
#Clam Antivirus clamscan and clamd, Sophos sweep, SAVI-Perl and Sophie.
#
#If you have Postfix, check its chroot setup script for further hints:
#postfix-xxx/examples/chroot-setup/<YOUR-OS> and BASIC_CONFIGURATION_README.
#
#
#exit   # This is NOT an automatic script!!!
       # Don't execute commands without knowing what they will do!!!


# !!! ESSENTIAL !!!, DO NOT FORGET to cd to your new chroot home directory
# before running commands below, as most of them use relative paths!
#
umask 0022
#mkdir /var/amavis
cd /var/amavis


# make directory structure within the current directory (/var/amavis)

FILES="etc dev var/run var/virusmails \
  usr/bin usr/lib usr/libexec usr/share usr/share/zoneinfo \
  usr/share/misc usr/share/spamassassin etc/mail/spamassassin \
  usr/local/lib/perl5/site_perl \
  var/virusmails/spam var/virusmails/virus var/virusmails/banned var/virusmails/badh var/virusmails/archive \
  home var/db/amavis scratch/tmp-am scratch/tmp-sys"
for file in $FILES; do
  [ -d $file ] || mkdir -p $file
done

# optional, depending on template in $*_quarantine_method :
chown amavis:amavis var/virusmails/spam var/virusmails/virus var/virusmails/banned var/virusmails/badh var/virusmails/archive

# devices management is delegated to host

# make a symbolic link so that chrooted processes can refer to the
# home directory as /var/amavis (same as not-chrooted), and need not have
# to handle it differently (i.e. referring to it as  / )
rm -rf var/amavis; ln -s .. var/amavis
# actually, the following is more general:  d=`pwd`; ln -s / $d$d


# copy required binaries to /var/amavis/usr/bin
FILES="usr/bin/file usr/bin/ar bin/pax usr/bin/gzip usr/bin/bzip2 \
  usr/local/bin/nomarch usr/local/bin/arc \
  usr/local/bin/unrar usr/local/bin/rar \
  usr/local/bin/arj usr/local/bin/unarj \
  usr/local/bin/zoo usr/local/bin/lha usr/local/bin/tnef \
  usr/local/bin/lzop usr/local/bin/freeze \
  usr/local/bin/rpm2cpio usr/local/bin/ripole usr/local/bin/cabextract \
  usr/local/bin/clamscan usr/local/bin/sweep usr/local/sbin/sophie \
  usr/local/bin/dccproc usr/local/bin/pyzor \
  usr/bin/altermime usr/bin/lz4c \
  usr/bin/7z usr/lib/p7zip/7z usr/bin/7za usr/lib/p7zip/7za"
for file in $FILES; do
  [ -d ${file%/*} ] || mkdir -p ${file%/*}
  if [ -f /${file} ]; then rm -f ${file} && cp /${file} ${file}; fi
  if [ -f  ${file} ]; then chmod a+rX ${file}; fi
done

# copy needed /etc files to /var/amavis/etc
# hosts and resolv.conf must be copied at boot time
FILES="etc/protocols etc/services etc/netconfig \
  etc/localtime \
  etc/nsswitch.conf etc/svc.conf etc/host.conf"
for file in $FILES; do
  [ -d ${file%/*} ] || mkdir -p ${file%/*}
  if [ -f /${file} ]; then rm -f ${file} && cp /${file} ${file}; fi
  if [ -f  ${file} ]; then chmod a+rX ${file}; fi
done

# SECURITY NOTE:
#   It is likely that the /etc/passwd file is not even needed in the jail.
#   Whether it is needed or not depends on external programs used for virus
#   and spam checks. Even when the /etc/passwd file in jail is needed, it
#   need not provide most regular system usernames and should not provide
#   their valid passwords; a heavily stripped down or faked version of the
#   file in the jail suffices for most purposes; also, there is hardly
#   any need for UID 0 usernames (e.g. root) in the chrooted /etc/passwd
#   file and such usernames are to be avoided.

# copy time zones data /usr/share/zoneinfo (or perhaps /usr/lib/zoneinfo)
#cp -pR /usr/share/zoneinfo usr/share/  # FreeBSD

# copy shared libraries to /var/amavis/lib
#   (check:  ldd /var/amavis/usr/bin/*  to see which ones are needed)

rm -rf lib; ln -s usr/lib .
rm -rf libexec; ln -s usr/libexec .

##FreeBSD:
#for j in \
#  /usr/lib/libc.so* /usr/lib/libc_r.so* /usr/lib/libm.so* \
#  /usr/lib/libthr.so* /usr/lib/libstdc++.so* \
#  /usr/lib/libz.so* /usr/lib/libz2.so* \
#  /usr/lib/libmagic.so* /usr/local/lib/libsavi.so* \
#  /usr/local/lib/libclamav.so.* /usr/local/lib/libgmp.so.*
#do cp -p $j usr/lib/; done
#cp -p /usr/libexec/ld-elf.so.1 usr/libexec/

#Linux:
LIBLIST=$(for name in \
  libc.musl ld-musl \
  libgcc_s libstdc++ \
  libmagic; do
  for f in /usr/lib/${name}*.so* /lib/${name}*.so*; do
    if [ -f "$f" ]; then  echo ${f#/}; fi;
  done;
done)

if [ -n "$LIBLIST" ]; then
  for f in $LIBLIST; do
   rm -f "$f"
  done
  tar cf - -C / $LIBLIST 2>/dev/null |tar xf -
fi

# UTF8 data files needed by Perl Unicode support:
rm -rf usr/local/lib/perl5/site_perl/*; cp -pR /usr/share/perl5/core_perl/unicore/ usr/local/lib/perl5/site_perl/
#
# on OpenBSD 3.8 that would be something like:
#   cp -pR /usr/libdata/perl5/unicore/ usr/libdata/perl5/


# needed by SpamAssassin:

#cp -p  /etc/mail/spamassassin/{*.pre,*.cf} etc/mail/spamassassin/
#cp -pR /usr/local/share/spamassassin usr/share/  # FreeBSD
rm -rf usr/share/spamassassin; cp -pR /usr/share/spamassassin usr/share/  # Linux

# Razor2 (if called from SpamAssassin):
#echo 'debuglevel = 0' >>/etc/razor-agent.conf
#cp /etc/razor-agent.conf etc/

# magic files needed by file(1). Different versions and installations expect
# magic files in different locations. Use the most recent version of file(1)
# and check its documentation. Some usual locations are:
#cp -p /usr/local/share/file/*  usr/local/share/file/
rm -f usr/share/misc/magic*; cp -p /usr/share/misc/magic* usr/share/misc/
#cp -p /usr/share/magic         usr/share/

# needed by AV scanners (ClamAV)
#mkdir -p var/db/clamav
#cp -pR /var/db/clamav var/db/
#cp /usr/local/bin/freshclam /usr/local/sbin/clamd usr/bin/
#cp /usr/local/etc/clamd.conf etc/
# Start clamd and freshclam:
#   chroot -u amavis /var/amavis /usr/sbin/clamd
#   chroot -u amavis /var/amavis /usr/bin/freshclam -d \
#     -c 4 --log-verbose --datadir=/usr/local/share/clam \
#     -l /var/log/clam-update.log

# needed by AV scanners (Sophos)
#mkdir -p usr/local/sav
#cp -pR /usr/local/sav usr/local/

# Subdirectory 'scratch' may reside on a volatile file system (tmpfs)

# set protection and ownership
chown -R root:root usr/ dev/ etc/ var/ scratch/
chown    root:root .
chown -R amavis:amavis home scratch/tmp-am var/db/amavis var/virusmails
#chown -R clamav:clamav var/db/clamav
chmod 751 . scratch var
chmod 1777 scratch/tmp-sys
rm -rf var/tmp; ln -s ../scratch/tmp-sys var/tmp
rm -rf tmp; ln -s scratch/tmp-sys tmp
rm -rf tmp-am; ln -s scratch/tmp-am  tmp-am
rm -rf db; ln -s var/db/amavis db   # for compatibility with traditional location

# /etc/passwd: set home directory of user amavis to /var/amavis/home !!!


# Daemonized virus scanners (e.g. Sophie, ClamD) may be
# started in the same chroot jail, or not.  E.g.
#   chroot /var/amavis /usr/bin/sophie -D
#
# If you want, you may now remove /usr/local/sav and make a link instead,
# to avoid having two copies of Sophos database:
#   ln -s /var/amavis/usr/local/sav /usr/local/sav
# consider:
#   ln -s /var/amavis/var/run/sophie      /var/run/     # Sophie socket
#   ln -s /var/amavis/var/run/sophie.pid  /var/run/

# Programs may be tested individually to see if they are happy
# in the chroot jail:
#
perl -Te 'use POSIX; $ENV{PATH}="/usr/bin";
         $uid=getpwnam("amavis")   or die "E1:$!";
         chroot "/var/amavis"     or die "E2:$!"; chdir "/";
         POSIX::setuid($uid)      or die "E3:$!";
         exec qw(file /etc/amavisd.conf) or die "E5:$!"' 1> /dev/null; exit $?
# or...
#    ... exec qw(file /usr/bin/gzip)   or die "E5:$!"'; echo $?
#    ... exec qw(gzip -d 0.lis.gz)     or die "E5:$!"'; echo $?
#    ... system "gzip 0.lis >0.lis.gz"; printf("E5: %d, %d=0x%x\n",$!,$?,$?)'
#    ... open(STDOUT,">0.lis.gz") or die "E5:$!";
#          exec qw(gzip -c 0.lis) or die "E6:$!"'; echo $
#    ... exec qw(clamscan /etc/resolv.conf) or die "E5:$!"'; echo $?

#Edit /var/amavis/etc/amavisd.conf, setting:
#  $MYHOME = '/var/amavis';
#  $ENV{TMPDIR} = $TEMPBASE = "$MYHOME/tmp-am";
#  $daemon_chroot_dir = $MYHOME;
#  $helpers_home = "$MYHOME/home";  # prefer $MYHOME clean and owned by root?
#  $db_home   = "$MYHOME/var/db/amavis";
#  $pid_file  = "$helpers_home/amavisd.pid";
#  $lock_file = "$helpers_home/amavisd.lock";
#  $QUARANTINEDIR = "$MYHOME/var/virusmails";
#
#Logging should preferably be directed to syslog. Configure syslogd to
#provide a socket in the amavis jail (option -l on FreeBSD, option -a
#on OpenBSD and Linux). Under FreeBSD place something like:
#  syslogd_flags="-l /var/amavis/var/run/log -ss"
#into /etc/rc.conf .
#
#Because the program starts outside the chroot jail and brings-in all Perl
#modules first, there is fortunately no need to make a copy of Perl modules
#inside the jail.
#
#If Perl complains about missing modules, add them to the list
#in file amavisd:
#
#    fetch_modules('REQUIRED BASIC MODULES', qw(
#       Exporter POSIX Fcntl Socket Errno Time::HiRes
#       IO::File IO::Socket IO::Wrap IO::Stringy
#    ...
#
#With earlier version of Perl you might need to add autoloaded modules
#to the list, such as:
#        auto::POSIX::setgid auto::POSIX::setuid
#
#
#As SpamAssassin loads its rules files only after chrooting, these need
#to be made available in the jail. A common procedure is to tell sa-update
#the directory that needs updating:
#  # sa-update --updatedir /var/amavis/var/lib/spamassassin/3.003000
#and periodically refresh them.
#
#
#NOTE:
#  OpenBSD chroot specifics are described in the document
#  http://www.flakshack.com/anti-spam, by Scott Vintinner.
#
#NOTE:
#  See note about Net::Server at:
#  http://www.ijs.si/software/amavisd/#faq-net-server
