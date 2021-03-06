#/bin/sh


SCRIPT_NAME=`basename $0 | sed -e "s/.sh$//"`
[ -z "${TMP_DIR}" ] && TMP_DIR=/tmp
TMP_FILE="${TMP_DIR}/${SCRIPT_NAME}.tmp.$$"
MYSQL_PWD="passwd"

info() {
  echo `date +%Y%m%d.%H%M%S`" "$*
  return 0
}

cd $HOME
info "Configuring MySQL Backup Software"
info "Detailed Log file can be found in ${TMP_FILE}"

info "Configuring user .my.cnf"
echo "[client]
user=root
password=${MYSQL_PWD}" > $HOME/.my.cnf
mysql -e "SELECT VERSION()"

info "Configure example server my.cnf"
echo "[mysqld]
server-id= 1
log-bin=mysql-bin
innodb_data_file_path=ibdata1:500M:autoextend
innodb_buffer_pool_size=500M
innodb_log_file_size=64M
innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT" > /tmp/my.cnf
sudo cp /tmp/my.cnf /etc/mysql/conf.d

info "Restarting MySQL"
(
sudo service mysql stop
sudo rm -f /var/lib/mysql/ib_logfile0 /var/lib/mysql/ib_logfile1
sudo service mysql start
) >> ${TMP_FILE}
sudo ls -lh /var/lib/mysql

[ `uname -m` != "x86_64" ] && echo "ERROR: The following steps require a 64bit architecture"

info "Installing Percona XtraBackup"
(
rm -f xtrabackup* percona-xtrabackup*
#wget http://www.percona.com/redir/downloads/XtraBackup/XtraBackup-1.6.5/deb/oneiric/x86_64/xtrabackup_1.6.5-328.oneiric_amd64.deb
wget http://www.percona.com/redir/downloads/XtraBackup/BETA/1.9.2/deb/oneiric/x86_64/percona-xtrabackup_1.9.2-404.oneiric_amd64.deb
sudo apt-get install -y libaio1
sudo dpkg -i *xtrabackup*.deb 
) >> ${TMP_FILE} 2>&1
xtrabackup --version


info "Installing MySQL Enterprise Backup (MEB)"
info "Please download MEB from https://edelivery.oracle.com/ and rename to meb.zip in $HOME"
read X
if [ ! -f "meb.zip" ] 
then
  echo "ERROR: Unable to find meb.zip, skipping install"
else
  # Cleanup if rerun
  rm -rf meb-*
  sudo rm -f /opt/meb   
  sudo rm -rf /opt/meb-*

  sudo apt-get install unzip >> ${TMP_FILE}
  unzip -q meb.zip 

  sudo mv meb-*/ /opt
  sudo ln -s /opt/meb-*/ /opt/meb
  /opt/meb/bin/mysqlbackup --version  | head -1
fi


info "Installing mydumper"
(
sudo apt-get install -y make cmake g++
sudo apt-get install -y libglib2.0-dev libmysqlclient-dev zlib1g-dev libpcre3-dev
rm -rf mydumper-*
wget http://launchpad.net/mydumper/0.2/0.2.3/+download/mydumper-0.2.3.tar.gz
tar xvfz mydumper*.tar.gz
cd mydumper-*[0-9]/
cmake .
make
sudo cp mydumper myloader /usr/local/bin
) >> ${TMP_FILE} 2>&1
mydumper --version


exit 0
