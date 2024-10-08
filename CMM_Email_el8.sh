#!/bin/bash

# Mail Server Installer Script for CentMinMod Installer (EL8) [CMM]

# Scripted by Brijendra Sial @ Bullten Web Hosting Solutions [https://www.bullten.com]

RED='\033[01;31m'
RESET='\033[0m'
GREEN='\033[01;32m'
YELLOW='\e[93m'
WHITE='\e[97m'
BLINK='\e[5m'

#set -e
#set -x

echo " "
echo -e "$GREEN*******************************************************************************$RESET"
echo " "
echo -e $YELLOW"Mail Server Installer Script for CentMinMod Installer (EL8) [CMM]$RESET"
echo " "
echo -e $YELLOW"Installations of Postfix,Dovecot and Opendkim"$RESET
echo " "
echo -e $YELLOW"By Brijendra Sial @ Bullten Web Hosting Solutions [https://www.bullten.com]"$RESET
echo " "
echo -e $YELLOW"Web Hosting Company Specialized in Providing Managed VPS and Dedicated Server's"$RESET
echo " "
echo -e "$GREEN*******************************************************************************$RESET"

echo " "

bss=0
b=1
bs=1
r=1
d=1
f=1
MYSQL_ROOT=$(cat /root/.my.cnf | grep password | cut -d' ' -f1 | cut -d'=' -f2)
DATABASE_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)
ROUNDCUBE_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)
MY_HOST_NAME=$(grep -ir "MYHOSTNAME" /etc/centminmod/cmmemailconfig/email.conf| cut -d':' -f2)

echo " "
echo -e $GREEN"Initial Checkes are in Progress"$RESET
echo " "

if [ -n "$(grep -ir "inet:127.0.0.1:8891" /etc/postfix/main.cf)" ]; then
        if [ -z "$(grep -ir "inet:127.0.0.1:8893" /etc/postfix/main.cf)" ]; then
        echo " "
        echo -e $YELLOW"OpenDKIM is supposed to be Installed"$RESET
        echo " "
        echo -e $RED"opendmarc is not installed"$RESET
        echo " "
        echo -e $GEREEN"Installing opendmarc now"$RESET
        dnf install opendmarc -y

cat >> /etc/opendmarc.conf <<EOF
AuthservID HOSTNAME
IgnoreAuthenticatedClients true
IgnoreHosts /etc/opendmarc/ignore.hosts
RejectFailures true
RequiredHeaders true
TrustedAuthservIDs HOSTNAME
EOF

        touch /etc/opendmarc/ignore.hosts

        echo " "
        echo -e $GEREEN"Enabling DMARC in Postfix"$RESET
        echo " "
        sed -i 's/\inet:127.0.0.1:8891\b/&,inet:127.0.0.1:8893/' /etc/postfix/main.cf
        echo " "
        systemctl restart postfix && systemctl enable postfix
        echo " "
        echo -e $GEREEN"DMARC installed successfully"$RESET
        echo " "
        echo -e $GEREEN"Restarting opendmarc & Postfix"$RESET
        systemctl restart opendmarc && systemctl restart postfix
        echo " "
        echo -e $YELLOW"Your DMARC Details for domain is _dmarc TXT v=DMARC1; p=none; rua=mailto:; ruf=mailto:; fo=1"$RESET
        echo " "
        else
        echo " "
        echo -e $GREEN"Mail Server seems to be installed with DMARC"$RESET
        echo " "

        fi
fi

if [ -n "$(grep -ir "smtpd_milters" /etc/postfix/main.cf)" ]; then
        echo " "
        echo -e $YELLOW"Mail Server is supposed to be Installed"$RESET
        echo " "
        echo -e $GREEN"Checking New Mail Functions That are Necessary"$RESET
                if [ -n "$(grep -ir "check_policy_service" /etc/postfix/main.cf)" ]; then
                        echo " "
                        echo -e $YELLOW"SPF Policy Already Exist"$RESET
                        echo " "
                else
                        echo " "
                        echo -e $YELLOW"New Mail Functionm SPF Policy Can be Installed."$RESET
                        echo " "
                        read -e -p "$(echo -e $GREEN"Do you Want to Install SPF Policy for Your Mail Server (y/n)?:"$RESET) " choice
case "$choice" in
y|Y )
        echo " "
        sleep 3
        echo -e $GREEN"Installing SPF Policy"$RESET
        echo " "
        dnf install pypolicyd-spf -y
        sed -i '/reject_unauth_destination/ s/$/, check_policy_service unix:private\/spfcheck/' /etc/postfix/main.cf
cat >> /etc/postfix/master.cf <<EOF
spfcheck     unix  -       n       n       -       -       spawn
       user=nobody argv=/bin/python /usr/libexec/postfix/policyd-spf
EOF

echo " "
echo -e $GREEN"Installation of  SPF Policy Completed"$RESET
echo " "
sleep 2

postfix reload

;;
n|N )
        echo " "
        echo -e $YELLOW"I Am Not Going to Enable SPF Policy"$RESET
;;
* )
        echo " "
        echo "Invalid Option Selected"
        echo " "
;;
esac

                fi
fi

if [ -n "$(grep -ir "dovecot.pem" /etc/dovecot/dovecot.conf)" ]; then
        echo " "
        echo -e $YELLOW"Self Signed Certificate is supposed to be Installed"$RESET
        echo " "
        read -e -p "$(echo -e $GREEN"Do you Want to Install Letsencrypt SSL For Dovecot Mail Server (y/n)?:"$RESET) " choice

case "$choice" in
y|Y )
        echo " "
        sleep 3
        echo -e $GREEN"Installing SSL for Dovecot"$RESET
        echo " "
        sed -i "/^ssl_cert/i ssl_ca = </root/.acme.sh/${MY_HOST_NAME}_ecc/ca.cer" /etc/dovecot/dovecot.conf
        sed -i "s/\/etc\/pki\/dovecot\/certs\/dovecot.pem/\/root\/.acme.sh\/${MY_HOST_NAME}_ecc\/fullchain.cer/g" /etc/dovecot/dovecot.conf
        sed -i "s/\/etc\/pki\/dovecot\/private\/dovecot.pem/\/root\/.acme.sh\/${MY_HOST_NAME}_ecc\/$MY_HOST_NAME.key/g" /etc/dovecot/dovecot.conf

echo " "
echo -e $GREEN"Installation of Letsencrypt SSL For Dovecot Mail Server Succeded"$RESET
echo " "
sleep 2


dovecot reload

;;
n|N )
        echo " "
        echo -e $YELLOW"I Am Not Going to Enable SSL Certificate for Dovecot"$RESET
;;
* )
        echo " "
        echo "Invalid Option Selected"
        echo " "
;;
esac

else
        echo -e $YELLOW"SSL Certificate for Dovecot already exist"$RESET
        echo " "
fi




function input_data
{

read -e -p "$(echo -e $GREEN"Enter Your Hostname:"$RESET) " MY_HOST_NAME
echo " "
read -e -p "$(echo -e $GREEN"Enter Domain Name:"$RESET) " DOMAIN_NAME
echo " "
read -e -p "$(echo -e $GREEN"Enter Email Address to Create (i.e sales@${DOMAIN_NAME}):"$RESET) " EMAIL_USER
echo " "
read -e -p "$(echo -e $GREEN"Enter Email Password:"$RESET) " EMAIL_PASSWORD
echo " "

mkdir /etc/centminmod/cmmemailconfig

cat > /etc/centminmod/cmmemailconfig/email.conf << EOF
MYHOSTNAME:$MY_HOST_NAME
MYDOMAINNAME:$DOMAIN_NAME
EOF

sleep 5
echo ""
required_software
}

function required_software
{
dnf update -y

if  rpm -q postfix && rpm -q postfix-mysql > /dev/null ; then
        echo " "
        echo -e $YELLOW"postfix Installation Found. Skipping Its Installation"$RESET
        echo " "
cat >> /etc/centminmod/cmmemailconfig/email.conf << EOF
EXIST_POSTFIX:y
EOF

else
        echo " "
        echo -e $RED"postfix Installation Not Found. Installing it"$RESET
        echo " "
        dnf install postfix postfix-mysql -y
        echo " "
fi

dnf install mailx mutt -y
dnf install dovecot dovecot-mysql cyrus-sasl cyrus-sasl-devel -y
create_database
}

function create_database
{
# create database and apply permissions
mysql -uroot -p$MYSQL_ROOT -e "CREATE DATABASE mail;"
mysql -uroot -p$MYSQL_ROOT -e "CREATE USER mail_admin@localhost IDENTIFIED BY '$DATABASE_PASSWORD';"
mysql -uroot -p$MYSQL_ROOT -e "GRANT ALL PRIVILEGES ON mail.* TO 'mail_admin'@'localhost';"
mysql -uroot -p$MYSQL_ROOT -e "FLUSH PRIVILEGES;"
create_table
}

function create_table
{
# create required tables
mysql -uroot -p$MYSQL_ROOT -D mail -e "CREATE TABLE domains (domain varchar(50) NOT NULL, PRIMARY KEY (domain) );"
mysql -uroot -p$MYSQL_ROOT -D mail -e "CREATE TABLE forwardings (source varchar(80) NOT NULL, destination TEXT NOT NULL, PRIMARY KEY (source) );"
mysql -uroot -p$MYSQL_ROOT -D mail -e "CREATE TABLE users (email varchar(80) NOT NULL, password varchar(20) NOT NULL, PRIMARY KEY (email) );"
mysql -uroot -p$MYSQL_ROOT -D mail -e "CREATE TABLE transport ( domain varchar(128) NOT NULL default '', transport varchar(128) NOT NULL default '', UNIQUE KEY domain (domain) )"
create_email_account
}

function create_email_account
{
mysql -uroot -p$MYSQL_ROOT -D mail -e "INSERT INTO domains (domain) VALUES ('$DOMAIN_NAME');"
mysql -uroot -p$MYSQL_ROOT -D mail -e "INSERT INTO users (email, password) VALUES ('$EMAIL_USER', ENCRYPT('$EMAIL_PASSWORD'));"
if [ "$input" = '3' ] || [ "$input" = '4' ]; then
mkdir /etc/opendkim/keys/$DOMAIN_NAME
opendkim-genkey -D /etc/opendkim/keys/$DOMAIN_NAME/ -d $DOMAIN_NAME -s default
chown -R opendkim: /etc/opendkim/keys/$DOMAIN_NAME
mv /etc/opendkim/keys/$DOMAIN_NAME/default.private /etc/opendkim/keys/$DOMAIN_NAME/default

cat >> /etc/opendkim/KeyTable << EOF
default._domainkey.$DOMAIN_NAME $DOMAIN_NAME:default:/etc/opendkim/keys/$DOMAIN_NAME/default
EOF

cat >> /etc/opendkim/SigningTable << EOF
*@$DOMAIN_NAME default._domainkey.$DOMAIN_NAME
EOF

cat >> /etc/opendkim/TrustedHosts << EOF
$HOST_NAME
$DOMAIN_NAME
EOF
echo " "
echo -e $YELLOW"Your DKIM Details for domain $DOMAIN_NAME is default._domainkey.$DOMAIN_NAME $(cat /etc/opendkim/keys/$DOMAIN_NAME/default.txt | grep -Pzo 'v=DKIM1[^)]+(?=" )' | sed 's/h=rsa-sha256;/h=sha256;/' | perl -0e '$x = <>; $x =~ s/"\s+"//sg; print $x')"$RESET
echo " "
echo -e $YELLOW"SPF record To Be Set As Follows v=spf1 mx a ip4:$(ip -4 addr show eth0 | grep -oP "(?<=inet ).*(?=/)") ~all"$RESET
echo " "
echo -e $YELLOW"MX record To Be Set As Follows $DOMAIN_NAME 0 mail.$DOMAIN_NAME"$RESET
echo " "


systemctl restart postfix
systemctl restart opendkim

else
        postfix_mysql_configuration
fi
}

function postfix_mysql_configuration
{
# generate postfix mysql configuration
cat > /etc/postfix/mysql-virtual_domains.cf <<EOF
user = mail_admin
password = $DATABASE_PASSWORD
dbname = mail
query = SELECT domain AS virtual FROM domains WHERE domain='%s'
hosts = 127.0.0.1
EOF

cat > /etc/postfix/mysql-virtual_forwardings.cf << EOF
user = mail_admin
password = $DATABASE_PASSWORD
dbname = mail
query = SELECT destination FROM forwardings WHERE source='%s'
hosts = 127.0.0.1
EOF

cat > /etc/postfix/mysql-virtual_mailboxes.cf << EOF
user = mail_admin
password = $DATABASE_PASSWORD
dbname = mail
query = SELECT CONCAT(SUBSTRING_INDEX(email,'@',-1),'/',SUBSTRING_INDEX(email,'@',1),'/') FROM users WHERE email='%s'
hosts = 127.0.0.1
EOF

cat > /etc/postfix/mysql-virtual_email2email.cf << EOF
user = mail_admin
password = $DATABASE_PASSWORD
dbname = mail
query = SELECT email FROM users WHERE email='%s'
hosts = 127.0.0.1
EOF

apply_permission
}

function apply_permission
{
# apply permissions
chmod o= /etc/postfix/mysql-virtual_*.cf
chgrp postfix /etc/postfix/mysql-virtual_*.cf
groupadd -g 5000 vmail
useradd -g vmail -u 5000 vmail -d /home/vmail -m
ssl_cert
}

function ssl_cert
{
dnf install socat -y
cd /usr/local/src/centminmod/addons/
yes | ./acmetool.sh acmeinstall
#/root/.acme.sh/acme.sh --issue --nginx -d $MY_HOST_NAME
/root/.acme.sh/acme.sh --issue -d $MY_HOST_NAME -w /usr/local/nginx/html
echo " "
postfix_main_configuration
}

function postfix_main_configuration
{
# postfix main.cf configuration
postconf -e "myhostname = $MY_HOST_NAME"
postconf -e 'mydestination = localhost'
postconf -e 'mynetworks = 127.0.0.0/8'
postconf -e 'inet_interfaces = all'
postconf -e 'inet_protocols = ipv4'
postconf -e 'message_size_limit = 30720000'
postconf -e 'virtual_alias_domains ='
postconf -e 'virtual_alias_maps = proxy:mysql:/etc/postfix/mysql-virtual_forwardings.cf, mysql:/etc/postfix/mysql-virtual_email2email.cf'
postconf -e 'virtual_mailbox_domains = proxy:mysql:/etc/postfix/mysql-virtual_domains.cf'
postconf -e 'virtual_mailbox_maps = proxy:mysql:/etc/postfix/mysql-virtual_mailboxes.cf'
postconf -e 'virtual_mailbox_base = /home/vmail'
postconf -e 'virtual_uid_maps = static:5000'
postconf -e 'virtual_gid_maps = static:5000'
postconf -e 'smtpd_sasl_type = dovecot'
postconf -e 'smtpd_sasl_path = private/auth'
postconf -e 'smtpd_sasl_auth_enable = yes'
postconf -e 'broken_sasl_auth_clients = yes'
postconf -e 'smtpd_sasl_authenticated_header = yes'
postconf -e 'smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination'
postconf -e 'smtpd_use_tls = yes'
postconf -e 'smtp_tls_loglevel = 1'
postconf -e 'smtp_tls_security_level = may'
postconf -e 'smtp_tls_CApath = /etc/ssl/certs'
postconf -e 'smtpd_tls_CApath = /etc/ssl/certs'
postconf -e 'local_recipient_maps = unix:passwd.byname $virtual_alias_maps'
postconf -e 'smtpd_tls_protocols = TLSv1.2, TLSv1.1, !TLSv1, !SSLv2, !SSLv3'
postconf -e 'smtp_tls_protocols = TLSv1.2, TLSv1.1, !TLSv1, !SSLv2, !SSLv3'
postconf -e 'smtp_tls_ciphers = high'
postconf -e 'smtpd_tls_ciphers = high'
postconf -e 'smtpd_tls_mandatory_protocols = TLSv1.2, TLSv1.1, !TLSv1, !SSLv2, !SSLv3'
postconf -e 'smtp_tls_mandatory_protocols = TLSv1.2, TLSv1.1, !TLSv1, !SSLv2, !SSLv3'
postconf -e 'smtp_tls_mandatory_ciphers = high'
postconf -e 'smtpd_tls_mandatory_ciphers = high'
postconf -e 'smtpd_tls_mandatory_exclude_ciphers = MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL, aNULL'
postconf -e 'smtpd_tls_exclude_ciphers = MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL, aNULL'
postconf -e 'smtp_tls_mandatory_exclude_ciphers = MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL, aNULL'
postconf -e 'smtp_tls_exclude_ciphers = MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL, aNULL'
postconf -e 'tls_preempt_cipherlist = yes'
postconf -e "smtpd_tls_cert_file = /root/.acme.sh/${MY_HOST_NAME}_ecc/fullchain.cer"
postconf -e "smtpd_tls_key_file = /root/.acme.sh/${MY_HOST_NAME}_ecc/$MY_HOST_NAME.key"
postconf -e 'smtpd_tls_CAfile = /etc/ssl/certs/ca-bundle.crt'
postconf -e 'smtp_tls_CAfile = $smtpd_tls_CAfile'
postconf -e 'proxy_read_maps = $local_recipient_maps $mydestination $virtual_alias_maps $virtual_alias_domains $virtual_mailbox_maps $virtual_mailbox_domains $relay_recipient_maps $relay_domains $canonical_maps $sender_canonical_maps $recipient_canonical_maps $relocated_maps $transport_maps $mynetworks'
postconf -e 'virtual_transport = virtual'
postconf -e 'dovecot_destination_recipient_limit = 1'
postfix_master_configuration
}

function postfix_master_configuration
{
# postfix master.conf configuration
echo "
dovecot   unix  -       n       n       -       -       pipe
    flags=DRhu user=vmail:vmail argv=/usr/libexec/dovecot/deliver -f ${sender} -d ${recipient}
" >> /etc/postfix/master.cf
dovecot_configuration
}

function dovecot_configuration
{
# backup dovecot.conf
mv /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf-backup

# generate dovecot.conf
cat > /etc/dovecot/dovecot.conf << EOF
listen = *
protocols = imap pop3
log_timestamp = "%Y-%m-%d %H:%M:%S "
mail_location = maildir:/home/vmail/%d/%n
maildir_stat_dirs = yes
mail_privileged_group = postfix
namespace {
  type = private
  separator = .
  prefix = INBOX.
  inbox = yes
}
passdb {
  args = /etc/dovecot/dovecot-sql.conf
  driver = sql
}
service auth {
  unix_listener /var/spool/postfix/private/auth {
    group = postfix
    mode = 0660
    user = postfix
  }
  unix_listener auth-master {
    mode = 0600
    user = vmail
  }
  user = root
}
ssl_ca = </root/.acme.sh/${MY_HOST_NAME}_ecc/ca.cer
ssl_cert = </root/.acme.sh/${MY_HOST_NAME}_ecc/fullchain.cer
ssl_key = </root/.acme.sh/${MY_HOST_NAME}_ecc/$MY_HOST_NAME.key
userdb {
  args = uid=5000 gid=5000 home=/home/vmail/%d/%n allow_all_users=yes
  driver = static
}
protocol lda {
  auth_socket_path = /var/run/dovecot/auth-master
  log_path = /home/vmail/dovecot-deliver.log
  postmaster_address = $POSTMASTER
}
protocol pop3 {
  pop3_uidl_format = %08Xu%08Xv
}
EOF

# generate dovecot-sql.conf
cat > /etc/dovecot/dovecot-sql.conf << EOF
driver = mysql
connect = host=127.0.0.1 dbname=mail user=mail_admin password=$DATABASE_PASSWORD
default_pass_scheme = CRYPT
password_query = SELECT email as user, password FROM users WHERE email='%u';
EOF

# apply permissions
chgrp dovecot /etc/dovecot/dovecot-sql.conf
chmod o= /etc/dovecot/dovecot-sql.conf

spf_policy
}

function spf_policy
{
dnf install pypolicyd-spf -y

sed -i '/reject_unauth_destination/ s/$/, check_policy_service unix:private\/spfcheck/' /etc/postfix/main.cf

cat >> /etc/postfix/master.cf <<EOF
spfcheck     unix  -       n       n       -       -       spawn
       user=nobody argv=/bin/python /usr/libexec/postfix/policyd-spf
EOF

setup_opendkim
}

function setup_opendkim
{
if  rpm -q opendkim && rpm -q opendkim > /dev/null ; then
        echo " "
        echo -e $YELLOW"opendkim Installation Found. Skipping Its Installation"$RESET
        echo " "
        dnf install opendkim opendkim-tools -y
        echo " "
cat >> /etc/centminmod/cmmemailconfig/email.conf << EOF
EXIST_OPENDKIM:y
EOF
        sleep 10
        else
        echo " "
        echo -e $RED"opendkim Installation Not Found. Installing it"$RESET
        echo " "
        dnf install opendkim opendkim-tools -y
        echo " "
fi

cat > /etc/opendkim.conf << EOF
AutoRestart             Yes
AutoRestartRate         10/1h
LogWhy                  Yes
Syslog                  Yes
SyslogSuccess           Yes
Mode                    sv
Canonicalization        relaxed/simple
ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
InternalHosts           refile:/etc/opendkim/TrustedHosts
KeyTable                /etc/opendkim/KeyTable
SigningTable            refile:/etc/opendkim/SigningTable
SignatureAlgorithm      rsa-sha256
Socket                  inet:8891@localhost
PidFile                 /var/run/opendkim/opendkim.pid
UMask                   022
UserID                  opendkim:opendkim
TemporaryDirectory      /var/tmp
EOF

mkdir /etc/opendkim/keys/$DOMAIN_NAME
opendkim-genkey -D /etc/opendkim/keys/$DOMAIN_NAME/ -d $DOMAIN_NAME -s default
chown -R opendkim: /etc/opendkim/keys/$DOMAIN_NAME
mv /etc/opendkim/keys/$DOMAIN_NAME/default.private /etc/opendkim/keys/$DOMAIN_NAME/default

cat >> /etc/opendkim/KeyTable << EOF
default._domainkey.$DOMAIN_NAME $DOMAIN_NAME:default:/etc/opendkim/keys/$DOMAIN_NAME/default
EOF

cat >> /etc/opendkim/SigningTable << EOF
*@$DOMAIN_NAME default._domainkey.$DOMAIN_NAME
EOF

cat >> /etc/opendkim/TrustedHosts << EOF
$HOST_NAME
$DOMAIN_NAME
EOF

postconf -e 'smtpd_milters = inet:127.0.0.1:8891'
postconf -e 'non_smtpd_milters = $smtpd_milters'
postconf -e 'milter_default_action = accept'
postconf -e 'milter_protocol = 2'

systemctl restart  opendkim
systemctl enable opendkim
systemctl restart postfix
systemctl restart dovecot
systemctl enable dovecot
echo " "
echo -e $GEREEN"Installing opendmarc now"$RESET
dnf install opendmarc -y

cat >> /etc/opendmarc.conf <<EOF
AuthservID HOSTNAME
IgnoreAuthenticatedClients true
IgnoreHosts /etc/opendmarc/ignore.hosts
RejectFailures true
RequiredHeaders true
TrustedAuthservIDs HOSTNAME
EOF

        touch /etc/opendmarc/ignore.hosts

        echo " "
        echo -e $GEREEN"Enabling DMARC in Postfix"$RESET
        echo " "
        sed -i 's/\inet:127.0.0.1:8891\b/&,inet:127.0.0.1:8893/' /etc/postfix/main.cf
        echo " "
        echo -e $GEREEN"DMARC installed successfully"$RESET
        echo " "
        echo -e $GEREEN"Restarting opendmarc && postfix"$RESET
        systemctl restart opendmarc && systemctl restart postfix
        systemctl enable opendmarc
        echo " "



setup_amavisd_spamassassin_clamav
}

function setup_amavisd_spamassassin_clamav
{
dnf install spamassassin amavisd-new clamav-server clamav-data clamav-update clamav-filesystem clamav clamav-scanner-systemd clamav-devel clamav-lib clamav-server-systemd -y
freshclam

sed -i "s/^Example/#Example/" /etc/clamd.d/scan.conf
sed -i '/clamd.sock/s/^#//g' /etc/clamd.d/scan.conf

MY_HOSTNAME_NAME=$(grep -ir "MYHOSTNAME" /etc/centminmod/cmmemailconfig/email.conf | cut -d':' -f2)
MY_DOMAIN_NAME=$(grep -ir "MYDOMAINNAME" /etc/centminmod/cmmemailconfig/email.conf | cut -d':' -f2)

sed -i "s/$mydomain = 'example.com'/$mydomain = '$MY_DOMAIN_NAME'/g" /etc/amavisd/amavisd.conf
sed -i "s/$myhostname = 'host.example.com'/$myhostname = '$MY_HOSTNAME_NAME'/g" /etc/amavisd/amavisd.conf
sed -i "s/\@local_domains_maps = ( \[\".\$mydomain\"/\\@local_domains_maps = ( \[\".\"/g" /etc/amavisd/amavisd.conf
sed -i "/\@local_domains_maps = ( \[\".\"/ a \@local_domains_acl = ( \".\$mydomain\"\ );" /etc/amavisd/amavisd.conf
sed -i "s/sa_tag_level_deflt  = 2.0/sa_tag_level_deflt  = -9999/g" /etc/amavisd/amavisd.conf

cat >> /etc/postfix/master.cf << EOF


amavisfeed unix    -       -       n        -      2     lmtp
      -o lmtp_data_done_timeout=1200
      -o lmtp_send_xforward_command=yes
      -o lmtp_tls_note_starttls_offer=no


127.0.0.1:10025 inet n    -       n       -       -     smtpd
     -o content_filter=
     -o smtpd_delay_reject=no
     -o smtpd_client_restrictions=permit_mynetworks,reject
     -o smtpd_helo_restrictions=
     -o smtpd_sender_restrictions=
     -o smtpd_recipient_restrictions=permit_mynetworks,reject
     -o smtpd_data_restrictions=reject_unauth_pipelining
     -o smtpd_end_of_data_restrictions=
     -o smtpd_restriction_classes=
     -o mynetworks=127.0.0.0/8
     -o smtpd_error_sleep_time=0
     -o smtpd_soft_error_limit=1001
     -o smtpd_hard_error_limit=1000
     -o smtpd_client_connection_count_limit=0
     -o smtpd_client_connection_rate_limit=0
     -o receive_override_options=no_header_body_checks,no_unknown_recipient_checks,no_milters
     -o local_header_rewrite_clients=
     -o smtpd_milters=
     -o local_recipient_maps=
     -o relay_recipient_maps=


submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,permit_mx_backup,reject
  -o content_filter=amavisfeed:[127.0.0.1]:10024


smtps     inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject
  -o content_filter=amavisfeed:[127.0.0.1]:10024

EOF



postconf -e 'content_filter = amavisfeed:[127.0.0.1]:10024'

#vi /etc/mail/spamassassin/local.cf

groupadd spamd
useradd -g spamd -s /bin/false -d /var/log/spamassassin spamd
chown spamd:spamd /var/log/spamassassin

#sed -i '/^smtp      inet/ s/$/ -o content_filter=spamassassin -o smtpd_milters=/' /etc/postfix/master.cf

#cat >> /etc/postfix/master.cf <<"EOF"
#spamassassin unix - n n - - pipe flags=R user=spamd argv=/usr/bin/spamc -e /usr/sbin/sendmail -oi -f ${sender} ${recipient}
#EOF

cat >> /etc/amavisd/amavisd.conf <<"EOF"
# Selectively disable some of the header checks
#
# Duplicate or multiple occurrence of a header field
$allowed_header_tests{'multiple'} = 0;

# Missing some headers. e.g. 'Date:'
$allowed_header_tests{'missing'} = 0;
EOF

echo " "

mkdir -p /run/clamd.scan
chown -R clamscan:clamscan /run/clamd.scan

systemctl start clamd@scan
systemctl enable clamd@scan

systemctl start spamassassin
systemctl enable spamassassin

systemctl start amavisd
systemctl enable amavisd

systemctl restart clamd@amavisd
systemctl enable clamd@amavisd

systemctl restart postfix

echo " "
echo -e $YELLOW"Your DKIM Details for domain $DOMAIN_NAME is default._domainkey.$DOMAIN_NAME $(cat /etc/opendkim/keys/$DOMAIN_NAME/default.txt | grep -Pzo 'v=DKIM1[^)]+(?=" )' | sed 's/h=rsa-sha256;/h=sha256;/' | perl -0e '$x = <>; $x =~ s/"\s+"//sg; print $x')"$RESET
echo " "
echo -e $YELLOW"SPF record To Be Set As Follows v=spf1 mx a ip4:$(hostname -I | awk '{ print $1 }') ~all"$RESET
echo " "
echo -e $YELLOW"MX record To Be Set As Follows $DOMAIN_NAME 0 $MY_HOST_NAME"$RESET
echo  " "
echo -e $YELLOW"Your Server Installation Config files are saved in /etc/centminmod/cmmemailconfig/email.conf"$RESET
echo  " "
echo -e $YELLOW"DMARC TXT Record To Be Set As _dmarc.$DOMAIN_NAME v=DMARC1; p=none; rua=mailto:; ruf=mailto:; fo=1"$RESET
echo " "
}

function dkim_generate
{
mkdir /etc/opendkim/keys/$DOMAIN_NAME
opendkim-genkey -D /etc/opendkim/keys/$DOMAIN_NAME/ -d $DOMAIN_NAME -s default
chown -R opendkim: /etc/opendkim/keys/$DOMAIN_NAME
mv /etc/opendkim/keys/$DOMAIN_NAME/default.private /etc/opendkim/keys/$DOMAIN_NAME/default

cat >> /etc/opendkim/KeyTable << EOF
default._domainkey.$DOMAIN_NAME $DOMAIN_NAME:default:/etc/opendkim/keys/$DOMAIN_NAME/default
EOF

cat >> /etc/opendkim/SigningTable << EOF
*@$DOMAIN_NAME default._domainkey.$DOMAIN_NAME
EOF

cat >> /etc/opendkim/TrustedHosts << EOF
$DOMAIN_NAME
EOF

echo " "
echo -e $YELLOW"Your DKIM Details for domain $DOMAIN_NAME is default._domainkey.$DOMAIN_NAME $(cat /etc/opendkim/keys/$DOMAIN_NAME/default.txt | grep -Pzo 'v=DKIM1[^)]+(?=" )' | sed 's/h=rsa-sha256;/h=sha256;/' | perl -0e '$x = <>; $x =~ s/"\s+"//sg; print $x')"$RESET
echo " "
}

function recreate_dkim
{
echo " "
read -e -p "$(echo -e $GREEN"Enter Domain Name:"$RESET) " DOMAIN_NAME
echo " "
if [ -n "$(mysql -uroot -p$MYSQL_ROOT -D mail -B -N -e "SELECT * FROM domains WHERE domain = '$DOMAIN_NAME';")" ]; then
        echo -e $GREEN"Deleting  DKIM key for $DOMAIN_NAME"$RESET
        sleep 3
        echo " "
        rm -rf /etc/opendkim/keys/$DOMAIN_NAME
        sed -i "/$DOMAIN_NAME/d" /etc/opendkim/KeyTable
        sed -i "/$DOMAIN_NAME/d" /etc/opendkim/SigningTable
        sed -i "/$DOMAIN_NAME/d" /etc/opendkim/TrustedHosts
        echo " "
        echo -e $GREEN"Creating DKIM key for $DOMAIN_NAME"$RESET
        sleep 3
        echo " "
        dkim_generate
else
        echo " "
        echo -e $RED"Domain $DOMAIN_NAME Not Found So Its Useless to Regenerate DKIM Key"
fi
}

function setup_roundcube
{
MY_HOST_NAME=$(grep -ir "MYHOSTNAME" /etc/centminmod/cmmemailconfig/email.conf| cut -d':' -f2)
dnf install java-11-openjdk-devel -y
wget -P /usr/local/nginx/html https://github.com/roundcube/roundcubemail/releases/download/1.6.7/roundcubemail-1.6.7.tar.gz
tar -C /usr/local/nginx/html -zxvf /usr/local/nginx/html/roundcubemail-*.tar.gz
rm -f /usr/local/nginx/html/roundcubemail-*.tar.gz
mv /usr/local/nginx/html/roundcubemail-* /usr/local/nginx/html/roundcube

mv /usr/local/nginx/html/roundcube/composer.json-dist /usr/local/nginx/html/roundcube/composer.json
/usr/local/nginx/html/roundcube/bin/install-jsdeps.sh

(cd /usr/local/nginx/html/roundcube/ && curl -sS https://getcomposer.org/installer | php && yes | php composer.phar install --no-plugins --no-scripts --no-dev)

chown nginx:nginx -R /usr/local/nginx/html/roundcube
chmod 777 -R /usr/local/nginx/html/roundcube/temp/
chmod 777 -R /usr/local/nginx/html/roundcube/logs/

mysql -uroot -p$MYSQL_ROOT -e "CREATE DATABASE roundcube;"
mysql -uroot -p$MYSQL_ROOT -e "CREATE USER roundcube@localhost IDENTIFIED BY '$ROUNDCUBE_PASSWORD';"
mysql -uroot -p$MYSQL_ROOT -e "GRANT ALL PRIVILEGES ON roundcube.* TO 'roundcube'@'localhost';"
mysql -uroot -p$MYSQL_ROOT -e "FLUSH PRIVILEGES;"

mysql -u root -p$MYSQL_ROOT 'roundcube' < /usr/local/nginx/html/roundcube/SQL/mysql.initial.sql

cp /usr/local/nginx/html/roundcube/config/config.inc.php.sample /usr/local/nginx/html/roundcube/config/config.inc.php

sed -i "s|^\(\$config\['db_dsnw'\] =\).*$|\1 \'mysqli://roundcube:$ROUNDCUBE_PASSWORD@localhost/roundcube\';|" /usr/local/nginx/html/roundcube/config/config.inc.php
sed -i "s|^\(\$config\['smtp_server'\] =\).*$|\1 \'localhost\';|" /usr/local/nginx/html/roundcube/config/config.inc.php
sed -i "s|^\(\$config\['smtp_host'\] =\).*$|\1 \'tls://${MY_HOST_NAME}:587\';|" /usr/local/nginx/html/roundcube/config/config.inc.php
sed -i "s|^\(\$config\['smtp_user'\] =\).*$|\1 \'%u\';|" /usr/local/nginx/html/roundcube/config/config.inc.php
sed -i "s|^\(\$config\['smtp_pass'\] =\).*$|\1 \'%p\';|" /usr/local/nginx/html/roundcube/config/config.inc.php
sed -i "s|^\(\$config\['create_default_folders'\] =\).*$|\1 \'true\';|" /usr/local/nginx/html/roundcube/config/defaults.inc.php
#sed -i "s|^\(\$config\['support_url'\] =\).*$|\1 \'mailto:${E}\';|" /usr/local/nginx/html/roundcube/config/config.inc.php

deskey=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)
sed -i "s|^\(\$config\['des_key'\] =\).*$|\1 \'${deskey}\';|" /usr/local/nginx/html/roundcube/config/config.inc.php

MY_HOSTNAME_NAME=$(grep -ir "MYHOSTNAME" /etc/centminmod/cmmemailconfig/email.conf | cut -d':' -f2)
sed -i "s|^\(\$config\['smtp_server'\] =\).*$|\1 \'tls://$MY_HOSTNAME_NAME\';|" /usr/local/nginx/html/roundcube/config/config.inc.php

nprestart

rm -rf /usr/local/nginx/html/roundcube/installer

echo " "
echo -e $YELLOW"Your Server Roundcube Access url is http://$(hostname -I | awk '{ print $1 }')/roundcube"$RESET
echo  " "
}

function update_roundcube
{
echo " "
read -e -p "$(echo -e $RED"Enter the version of roundcube you want to upgrade i.e 1.4.3:"$RESET) " rndc
echo " "
wget -P /usr/local/nginx/html https://github.com/roundcube/roundcubemail/releases/download/$rndc/roundcubemail-$rndc-complete.tar.gz
tar -C /usr/local/nginx/html -zxvf /usr/local/nginx/html/roundcubemail-$rndc*.tar.gz
rm -rf /usr/local/nginx/html/roundcubemail-$rndc*.tar.gz
mv /usr/local/nginx/html/roundcubemail-$rndc* /usr/local/nginx/html/roundcube-$rndc
/usr/local/nginx/html/roundcube/bin/install-jsdeps.sh
/usr/local/nginx/html/roundcube-$rndc/bin/installto.sh /usr/local/nginx/html/roundcube << EOF
y
EOF
rm -rf /usr/local/nginx/html/roundcube-$rndc
}

function delete_roundcube
{
read -e -p "$(echo -e $RED"Warning Your Are About to Remove Roundcube (y/n)?:"$RESET) " choice
case "$choice" in
y|Y )
        echo " "
        sleep 3
        rm -rf /usr/local/nginx/html/roundcube
        mysql -uroot -p$MYSQL_ROOT -e "drop database roundcube;"
        mysql -uroot -p$MYSQL_ROOT -e "drop user roundcube@localhost;"
        echo -e $YELLOW"Roundcube Deleted Successfully"$RESET
;;
n|N )
        echo " "
        echo -e $YELLOW"Uninstallation of Roundcube Declined"$RESET
;;
* )
        echo " "
        echo "Invalid Option Selected"
        echo " "
;;
esac
}

function remove_mail_server
{
echo " "
cp -R /home/vmail /home/vmail_old
dnf remove mutt -y
dnf remove dovecot dovecot-mysql cyrus-sasl cyrus-sasl-devel pypolicyd-spf spamassassin amavisd-new clamav-server clamav-data clamav-update clamav-filesystem clamav clamav-scanner-systemd clamav-devel clamav-lib clamav-server-systemd opendmarc -y
rm -rf /etc/dovecot
userdel -r vmail
userdel -r spamd
mysql -uroot -p$MYSQL_ROOT -e "drop database mail;"
mysql -uroot -p$MYSQL_ROOT -e "drop user mail_admin@localhost;"
sed -i -e '/^spfcheck/,+1d' /etc/postfix/master.cf
sed -i -e '/^dovecot/,+1d' /etc/postfix/master.cf
sed -i "/^amavisfeed/Q" /etc/postfix/master.cf
echo " "

POSTFIX=$(grep -ir "EXIST_POSTFIX" /etc/centminmod/cmmemailconfig/email.conf | cut -d":" -f2)
if [ "$POSTFIX" = "y" ]; then
        echo " "
        echo "Postfix Already existed. Skipping Uninstallation"
        echo " "
        HOST=$(grep -ir "MYHOSTNAME" /etc/centminmod/cmmemailconfig/email.conf | cut -d":" -f2)
        sed -i "/myhostname = $HOST/Q" /etc/postfix/main.cf
        systemctl restart postfix
else
        echo " "
        dnf remove postfix -y
        rm -rf /etc/postfix
        echo " "
fi

OPENDKIM=$(grep -ir "EXIST_OPENDKIM" /etc/centminmod/cmmemailconfig/email.conf | cut -d":" -f2)
if [ "$OPENDKIM" = "y" ]; then
        echo " "
        echo "OpenDKIM Already existed. Skipping Uninstallation"
        echo " "
        TABLES=$(mysql -u root --password=${MYSQL_ROOT} -D mail -B -N -e "SELECT domain FROM domains;")
        for bss in $TABLES; do
                echo "Listing Content of Column Domain $bss"
                echo " "
                rm -rf /etc/opendkim/keys/$bss
        done
        systemctl restart opendkim
        rm -rf /etc/centminmod/cmmemailconfig
else
        echo " "
        dnf remove opendkim opendkim-tools -y
        rm -rf /etc/opendkim
        echo " "
        rm -rf /etc/centminmod/cmmemailconfig
fi

}

function add_email
{
echo " "
read -e -p "$(echo -e $GREEN"Enter Email Address:"$RESET) " EMAIL_USER
DOMAIN_NAME=$(printf $EMAIL_USER | cut -d"@" -f2)
if [ -z "$(mysql -uroot -p$MYSQL_ROOT -D mail -B -N -e "SELECT email FROM users WHERE email = '$EMAIL_USER';")" ] && [ -n "$(mysql -uroot -p$MYSQL_ROOT -D mail -B -N -e "SELECT * FROM domains WHERE domain = '$DOMAIN_NAME';")" ]; then
read -e -p "$(echo -e $GREEN"Enter Email Password:"$RESET) " EMAIL_PASSWORD
mysql -uroot -p$MYSQL_ROOT -D mail -e "INSERT INTO users (email, password) VALUES ('$EMAIL_USER', ENCRYPT('$EMAIL_PASSWORD'));"
echo " "
echo -e $GREEN"Email ID $EMAIL_USER Successfully Added"$RESET
else
echo " "
echo -e $RED"Impossible to Create Email Account as it Already Exist or Domain Doesnt Exist"$RESET
fi
}

function remove_email
{
read -e -p "$(echo -e $GREEN"Enter Email Address:"$RESET) " EMAIL_USER
echo " "
if [ -n "$(mysql -uroot -p$MYSQL_ROOT -D mail -B -N -e "SELECT email FROM users WHERE email = '$EMAIL_USER';")" ]; then
mysql -u root --password=${MYSQL_ROOT} -D mail -B -N -e "DELETE FROM users WHERE email = '$EMAIL_USER';"
echo " "
echo -e $YELLOW"Email ID $EMAIL_USER Successfully Removed from Database"$RESET
else
echo " "
echo -e $RED"Email ID $EMAIL_USER Doesnt Exist"$RESET
fi
}

function change_password_email
{
echo " "
read -e -p "$(echo -e $GREEN"Enter Email Address:"$RESET) " EMAIL_USER
if [ -n "$(mysql -uroot -p$MYSQL_ROOT -D mail -B -N -e "SELECT email FROM users WHERE email = '$EMAIL_USER';")" ]; then
read -e -p "$(echo -e $GREEN"Enter Email New Password:"$RESET) " EMAIL_PASSWORD
mysql -u root --password=${MYSQL_ROOT} -D mail -B -N -e "update users set password=ENCRYPT('$EMAIL_PASSWORD') where email='$EMAIL_USER';"
echo " "
echo -e $YELLOW"Password for $EMAIL_USER Successfully Changed"$RESET
else
echo " "
echo -e $RED"Cannot Change Password as Email Doesnt exist"$RESET
fi
}

function add_forwarding
{
echo " "
echo -e $YELLOW"You Have Selected Option to Add Forwarding"$RESET
echo " "
read -e -p "$(echo -e $GREEN"Enter Source Email:"$RESET) " SOURCE_EMAIL
if [ -n "$(mysql -uroot -p$MYSQL_ROOT -D mail -B -N -e "SELECT email FROM users WHERE email = '$SOURCE_EMAIL';")" ]; then
echo " "
read -e -p "$(echo -e $GREEN"Enter Destination  Email:"$RESET) " DESTINATION_EMAIL
echo " "
mysql -u root --password=${MYSQL_ROOT} -D mail -B -N -e "INSERT INTO  forwardings (\`source\`, \`destination\`) VALUES ('$SOURCE_EMAIL', '$DESTINATION_EMAIL');"
echo " "
echo -e $YELLOW"Successfully Forwarded mail from $SOURCE_EMAIL to $DESTINATION_EMAIL"$RESET
else
echo " "
echo -e $RED"Email $SOURCE_EMAIL Doesnt Exist so Impossible to Forward"$RESET
fi
}

function remove_forwarding
{
echo " "
echo -e $YELLOW"You Have Selected Option to Remove Forwarding"$RESET
echo " "
read -e -p "$(echo -e $GREEN"Enter Source Email:"$RESET) " SOURCE_EMAIL
if [ -n "$(mysql -uroot -p$MYSQL_ROOT -D mail -B -N -e "SELECT source FROM forwardings WHERE source = '$SOURCE_EMAIL';")" ]; then
echo " "
echo -e $YELLOW"Looks Like Forwarding is Set"$RESET
read -e -p "$(echo -e $RED"Warning Your Are About to Remove Forwarding for $SOURCE_EMAIL (y/n)?:"$RESET) " choice
case "$choice" in
               y|Y )
                        echo " "
                        echo -e $YELLOW"Removing Forwarding for Email $SOURCE_EMAIL"$RESET
                        echo " "
                        mysql -u root --password=${MYSQL_ROOT} -D mail -B -N -e "DELETE FROM forwardings where source = '$SOURCE_EMAIL';"
                        echo " "
                        echo -e $YELLOW"Forwarding for Email $SOURCE_EMAIL Sucessfully Removed"$RESET
                        echo " "
        ;;
               n|N )
                        echo " "
                        echo -e $YELLOW"You Asked Me to Not Remove Forwarding :)"$RESET
                        echo " "
               ;;
               * )
                        echo " "
                        echo "Invalid Option Selected"
                        echo " "
               ;;
esac
else
        echo " "
        echo -e $RED"Email $SOURCE_EMAIL Doesnt Seems to Be Forwarded"$RESET
        echo " "
fi
}

function update_forwarding
{
echo " "
echo -e $YELLOW"You Have Selected Option to Update Forwarding"$RESET
echo " "
read -e -p "$(echo -e $GREEN"Enter Source Email:"$RESET) " SOURCE_EMAIL
if [ -n "$(mysql -uroot -p$MYSQL_ROOT -D mail -B -N -e "SELECT source FROM forwardings WHERE source = '$SOURCE_EMAIL';")" ]; then
echo " "
echo -e $YELLOW"Looks Like Forwarding Email is Set"$RESET
read -e -p "$(echo -e $RED"Warning Your Are About to Update Forwarding Email for $SOURCE_EMAIL (y/n)?:"$RESET) " choice
case "$choice" in
               y|Y )
                        echo " "
                        echo -e $YELLOW"Update Forwarding Email for Email $SOURCE_EMAIL"$RESET
                        echo " "
                        read -e -p "$(echo -e $GREEN"Enter New Destination Email:"$RESET) " DESTINATION_EMAIL
                        echo " "
                        mysql -u root --password=${MYSQL_ROOT} -D mail -B -N -e "update forwardings set destination=('$DESTINATION_EMAIL') where source='$SOURCE_EMAIL';"
                        echo " "
                        echo -e $YELLOW"Forwarding for Email $SOURCE_EMAIL Sucessfully Removed"$RESET
                        echo " "
        ;;
               n|N )
                        echo " "
                        echo -e $YELLOW"You Asked Me to Not Update Forwarding Email:)"$RESET
                        echo " "
               ;;
               * )
                        echo " "
                        echo "Invalid Option Selected"
                        echo " "
               ;;
esac
else
        echo " "
        echo -e $RED"Email $SOURCE_EMAIL Doesnt Seems to Be Forwarded"$RESET
        echo " "
fi
}


function start_display
{
        if [ -e "/etc/centminmod" ]; then
                echo -e $YELLOW"Centminmod Installation Detected"$RESET
                echo " "
                        while [ "$b" = 1 ]; do
                                echo -e $YELLOW"Select Option to Setup Mail Server on CMM:"$RESET
                                echo " "
                                echo -e $GREEN"1) Setup Mail Server (Postfix, Dovecot, OpenDKIM, SPF Policy, Amavisd, SpamAssassin and Clamav)"$RESET
                                echo " "
                                echo -e $GREEN"2) Roundcube Installation , Updation & Deletion"$RESET
                                echo " "
                                echo -e $GREEN"3) Create an Email for Non existing Domain"$RESET
                                echo " "
                                echo -e $GREEN"4) Add/Remove New Email or Change Password of Existing Email"$RESET
                                echo " "
                                echo -e $GREEN"5) Retrive and Regenerate DKIM Key for a Domain"$RESET
                                echo " "
                                echo -e $GREEN"6) Add/Remove Email Forwarding"$RESET
                                echo " "
                                echo -e $GREEN"7) Remove Mail Server (Postfix, Dovecot, OpenDKIM, SPF Policy,  Amavisd, SpamAssassin and Clamav)"$RESET
                                echo " "
                                echo -e $GREEN"8) Exit"$RESET
                                echo " "

                                #read input

                                read -e -p "$(echo -e $GREEN"Please enter your selection:"$RESET) " input

                                       if [ "$input" = '1' ]; then
                                                echo " "
                                                echo -e $YELLOW"Installing Mail server (Postfix, Dovecot, OpenDKIM, SPF Policy)"$RESET
                                                echo " "
                                                sleep 1
                                                input_data

                                        elif [ "$input" = '2' ]; then
                                                echo " "
                                                echo -e $YELLOW"Roundcube Installation | Updation | Deletion"$RESET
                                                sleep 1
                                                roundcube_display

                                        elif [ "$input" = '3' ]; then
                                                echo " "
                                                echo -e $YELLOW"Add A New Domain With Its Email ID"$RESET
                                                echo " "
                                                sleep 1
                                                read -e -p "$(echo -e $GREEN"Enter Domain Name:"$RESET) " DOMAIN_NAME
                                                if [ -z "$(mysql -uroot -p$MYSQL_ROOT -D mail -B -N -e "SELECT * FROM domains WHERE domain = '$DOMAIN_NAME';")" ]; then
                                                        read -e -p "$(echo -e $GREEN"Enter Email Address:"$RESET) " EMAIL_USER
                                                        read -e -p "$(echo -e $GREEN"Enter Email Password:"$RESET) " EMAIL_PASSWORD
                                                        create_email_account
                                                else
                                                        echo " "
                                                        echo -e $RED"Impossible to Add Existing Domain. Aborting :)"$RESET
                                                        echo " "
                                                fi

                                        elif [ "$input" = '4' ]; then
                                                echo " "
                                                echo -e $YELLOW"Setup New/Remove Email or Change Password"$RESET
                                                sleep 1
                                                add_remove_display

                                        elif [ "$input" = '5' ]; then
                                                echo " "
                                                echo -e $YELLOW"Retrive DKIM Key For A Domain"$RESET
                                                echo " "
                                                sleep 1
                                                dkim_display
                                                echo " "

                                        elif [ "$input" = '6' ]; then
                                                echo " "
                                                echo -e $YELLOW"Setup or Remove Email Forwarding"$RESET
                                                echo " "
                                                sleep 1
                                                forwarding_display
                                                echo " "

                                        elif [ "$input" = '7' ]; then
                                                echo " "
                                                echo -e $YELLOW"Removing Mail Server"$RESET
                                                echo " "
                                                sleep 1
                                                read -e -p "$(echo -e $RED"Warning Your Are About to Remove Mail Server (y/n)?:"$RESET) " choice
                                                case "$choice" in
                                                        y|Y )
                                                                remove_mail_server

                                                        ;;
                                                        n|N )
                                                                echo " "
                                                                echo -e $YELLOW"Uninstallation of Mail Server Declined"$RESET
                                                                echo " "
                                                        ;;
                                                        * )
                                                                echo " "
                                                                echo "Invalid Option Selected"
                                                                echo " "
                                                        ;;
                                                esac

                                        elif [ "$input" = '8' ]; then
                                                echo " "
                                                echo -e $YELLOW"Exiting"$RESET
                                                echo " "
                                                exit

                                        else
                                                echo " "
                                                echo -e $RED"You have Selected An Invalid Option"$RESET
                                                echo " "
                                        fi
                        done
        else

                echo " "
                echo -e $RED"Centminmod Installation Not Found"$RESET
                echo " "

        fi
}

function add_remove_display
{
        while [ "$bs" = 1 ]; do
             echo " "
             echo -e $YELLOW"Select Option to Add/Remove or Change Password of Email ID:"$RESET
             echo " "
             echo -e $GREEN"1) Do You Want To Add New Email ID"$RESET
             echo " "
             echo -e $GREEN"2) Do You Want to Remove Existing Email ID"$RESET
             echo " "
             echo -e $GREEN"3) Do You Want to Change Password of Existing Email ID"$RESET
             echo " "
             echo -e $GREEN"4) Back To Previous Screen"$RESET
             echo " "
             #read inputss

                read -e -p "$(echo -e $GREEN"Please enter your selection:"$RESET) " inputss

                if [ "$inputss" = '1' ]; then
                        echo " "
                        add_email
                        echo " "

                elif [ "$inputss" = '2' ]; then
                        echo " "
                        remove_email
                        echo " "

                elif [ "$inputss" = '3' ]; then
                        echo " "
                        change_password_email
                        echo " "

                elif [ "$inputss" = '4' ]; then
                        echo " "
                        start_display
                        echo " "
                else

                        echo " "
                        echo -e $RED"You Have Selected An Invalid Option"$RESET
                        echo " "
                fi
        done
}

function roundcube_display
{
        while [ "$r" = 1 ]; do
             echo " "
             echo -e $YELLOW"Select Option to Install | Update | Delete Roundcube"$RESET
             echo " "
             echo -e $GREEN"1) Do You Want to Install Roundcube"$RESET
             echo " "
             echo -e $GREEN"2) Do You Want to Update Roundcube"$RESET
             echo " "
             echo -e $GREEN"3) Do You Want to Delete Roundcube"$RESET
             echo " "
             echo -e $GREEN"4) Back To Previous Screen"$RESET
             echo " "
             #read inputss

                read -e -p "$(echo -e $GREEN"Please enter your selection:"$RESET) " inputss

                if [ "$inputss" = '1' ]; then
                        echo " "
                        setup_roundcube
                        echo " "

                elif [ "$inputss" = '2' ]; then
                        echo " "
                        update_roundcube
                        echo " "

                elif [ "$inputss" = '3' ]; then
                        echo " "
                        delete_roundcube
                        echo " "

                elif [ "$inputss" = '4' ]; then
                        echo " "
                        start_display
                        echo " "
                else

                        echo " "
                        echo -e $RED"You Have Selected An Invalid Option"$RESET
                        echo " "
                fi
        done
}

function forwarding_display
{
        while [ "$f" = 1 ]; do
             echo " "
             echo -e $YELLOW"Select Option to Add or Remove Email Forwarding"$RESET
             echo " "
             echo -e $GREEN"1) Add Email Forwarding"$RESET
             echo " "
             echo -e $GREEN"2) Remove Email Forwarding"$RESET
             echo " "
             echo -e $GREEN"3) Update Forwarding Email"$RESET
             echo " "
             echo -e $GREEN"4) Back To Previous Screen"$RESET
             echo " "
             #read inputss

                read -e -p "$(echo -e $GREEN"Please enter your selection:"$RESET) " inputss

                if [ "$inputss" = '1' ]; then
                        echo " "
                        add_forwarding
                        echo " "

                elif [ "$inputss" = '2' ]; then
                        echo " "
                        remove_forwarding
                        echo " "

                elif [ "$inputss" = '3' ]; then
                        echo " "
                        update_forwarding
                        echo " "

                elif [ "$inputss" = '4' ]; then
                        echo " "
                        start_display
                        echo " "
                else

                        echo " "
                        echo -e $RED"You Have Selected An Invalid Option"$RESET
                        echo " "
                fi
        done
}


function dkim_display
{
        while [ "$d" = 1 ]; do
             echo " "
             echo -e $YELLOW"Select Option to Retrieve  | Regenerate DKIM Key"$RESET
             echo " "
             echo -e $GREEN"1) Retrieve DKIM Key For A Domain"$RESET
             echo " "
             echo -e $GREEN"2) Regenerate DKIM Key For A Domain"$RESET
             echo " "
             echo -e $GREEN"3) Back To Previous Screen"$RESET
             echo " "
             #read inputss

                read -e -p "$(echo -e $GREEN"Please enter your selection:"$RESET) " inputss

                if [ "$inputss" = '1' ]; then
                        echo " "
                        read -e -p "$(echo -e $GREEN"Enter Domain Name:"$RESET) " DOMAIN_NAME
                        echo " "
                        echo -e $GREEN"DKIM Key for Domain $DOMAIN_NAME is Below:"$RESET
                        echo " "
                        echo -e $YELLOW"default._domainkey.$DOMAIN_NAME $(cat /etc/opendkim/keys/$DOMAIN_NAME/default.txt | grep -Pzo 'v=DKIM1[^)]+(?=" )' | sed 's/h=rsa-sha256;/h=sha256;/' | perl -0e '$x = <>; $x =~ s/"\s+"//sg; print $x')"$RESET
                        echo "$DKIM_KEY"
                        echo " "

                elif [ "$inputss" = '2' ]; then
                        echo " "
                        recreate_dkim
                        echo " "

                elif [ "$inputss" = '3' ]; then
                        echo " "
                        start_display
                        echo " "
                else

                        echo " "
                        echo -e $RED"You Have Selected An Invalid Option"$RESET
                        echo " "
                fi
        done
}
start_display
