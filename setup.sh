#!/bin/bash
export JAVA_HOME=/usr/local/java
export HADOOP_PREFIX=/usr/local/hadoop
HADOOP_VERSION=2.7.2
HADOOP_ARCHIVE=hadoop-${HADOOP_VERSION}.tar.gz
JAVA_VERSION=8u121
JAVA_ARCHIVE=jdk-${JAVA_VERSION}-linux-x64.tar.gz
HADOOP_MIRROR_DOWNLOAD=http://apache.mirror.quintex.com/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
GIRAPH_VERSION=1.2.0
GIRAPH_ARCHIVE=giraph-dist-${GIRAPH_VERSION}-hadoop2-bin.tar.gz
GIRAPH_DOWNLOAD=http://mirror.catn.com/pub/apache/giraph/giraph-${GIRAPH_VERSION}/${GIRAPH_ARCHIVE}

function fileExists {
	FILE=/vagrant/resources/$1
	if [ -e $FILE ]
	then
		return 0
	else
		return 1
	fi
}

function disableFirewall {
	echo "disabling firewall"
	service iptables save
	service iptables stop
	chkconfig iptables off
}

function installLocalJava {
	echo "installing oracle jdk"
	FILE=/vagrant/resources/$JAVA_ARCHIVE
	tar -xzf $FILE -C /usr/local
}

function installRemoteJava {
	echo "install open jdk"
	yum install -y java-1.8.0-openjdk
}

function installLocalHadoop {
	echo "install hadoop from local file"
	FILE=/vagrant/resources/$HADOOP_ARCHIVE
	tar -xzf $FILE -C /usr/local
}

function installRemoteHadoop {
	echo "install hadoop from remote file"
	curl -o /home/vagrant/hadoop-${HADOOP_VERSION}.tar.gz -O -L $HADOOP_MIRROR_DOWNLOAD
	tar -xzf /home/vagrant/hadoop-${HADOOP_VERSION}.tar.gz -C /usr/local
}

function setupJava {
	echo "setting up java"
	if fileExists $JAVA_ARCHIVE; then
		ln -s /usr/local/jdk1.8.0_121 /usr/local/java
	else
		ln -s /usr/lib/jvm/jre /usr/local/java
	fi
}

function setupHadoop {
	echo "creating hadoop directories"
	mkdir /tmp/hadoop-namenode
	mkdir /tmp/hadoop-logs
	mkdir /tmp/hadoop-datanode
	ln -s /usr/local/hadoop-${HADOOP_VERSION} /usr/local/hadoop
	echo "copying over hadoop configuration files"
	cp -f /vagrant/resources/core-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/hdfs-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/mapred-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/yarn-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/slaves /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/hadoop-env.sh /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/yarn-env.sh /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/yarn-daemon.sh /usr/local/hadoop/sbin
	cp -f /vagrant/resources/mr-jobhistory-daemon.sh /usr/local/hadoop/sbin
	echo "modifying permissions on local file system"
	chown -fR vagrant /tmp/hadoop-namenode
    chown -fR vagrant /tmp/hadoop-logs
    chown -fR vagrant /tmp/hadoop-datanode
	mkdir /usr/local/hadoop-${HADOOP_VERSION}/logs
	chown -fR vagrant /usr/local/hadoop-${HADOOP_VERSION}/logs
}

function setupEnvVars {
	echo "creating java environment variables"
	#if fileExists $JAVA_ARCHIVE; then
	#	echo export JAVA_HOME=/usr/local/jdk1.7.0_51 >> /etc/profile.d/java.sh
	#else
	#	echo export JAVA_HOME=/usr/lib/jvm/jre >> /etc/profile.d/java.sh
	#fi
	echo export JAVA_HOME=/usr/local/java >> /etc/profile.d/java.sh
	echo export PATH=\${JAVA_HOME}/bin:\${PATH} >> /etc/profile.d/java.sh
	
	echo "creating hadoop environment variables"
	cp -f /vagrant/resources/hadoop.sh /etc/profile.d/hadoop.sh
}

function setupHadoopService {
	echo "setting up hadoop service"
	cp -f /vagrant/resources/hadoop /etc/init.d/hadoop
	chmod 777 /etc/init.d/hadoop
	chkconfig --level 2345 hadoop on
}

function setupNameNode {
	echo "setting up namenode"
	/usr/local/hadoop-${HADOOP_VERSION}/bin/hdfs namenode -format myhadoop
}

function startHadoopService {
	echo "starting hadoop service"
	service hadoop start
}

function installHadoop {
	if fileExists $HADOOP_ARCHIVE; then
		installLocalHadoop
	else
		installRemoteHadoop
	fi
}

function installJava {
	if fileExists $JAVA_ARCHIVE; then
		installLocalJava
	else
		installRemoteJava
	fi
}

function initHdfsTempDir {
	$HADOOP_PREFIX/bin/hdfs --config $HADOOP_PREFIX/etc/hadoop dfs -mkdir /tmp
	$HADOOP_PREFIX/bin/hdfs --config $HADOOP_PREFIX/etc/hadoop dfs -chmod -R 777 /tmp
}

function installLocalGiraph {
	echo "installing local giraph"
	FILE=/vagrant/resources/$GIRAPH_ARCHIVE
	tar -xzf $FILE -C /usr/local
}

function installRemoteGiraph {
    echo "installing remote giraph"
    curl -o /home/vagrant/giraph-dist-1.2.0-hadoop2-bin.tar.gz http://mirror.catn.com/pub/apache/giraph/giraph-1.2.0/giraph-dist-1.2.0-hadoop2-bin.tar.gz
    tar -xzf /home/vagrant/giraph-dist-1.2.0-hadoop2-bin.tar.gz -C /usr/local
}

function installGiraph {
    if fileExists $GIRAPH_ARCHIVE; then
        installLocalGiraph
    else
        installRemoteGiraph
    fi
}

function setupGiraph {
    echo "setting up giraph"
    ln -s /usr/local/giraph-1.2.0-hadoop2-for-hadoop-2.5.1 /usr/local/giraph
    echo 'export PATH=/usr/local/giraph/bin:${PATH}' >> /home/vagrant/.bash_profile
    echo 'export HADOOP_HOME=${HADOOP_YARN_HOME}' >> /home/vagrant/.bash_profile
}

disableFirewall
installJava
installHadoop
setupJava
setupHadoop
setupEnvVars
setupNameNode
setupHadoopService
startHadoopService
initHdfsTempDir
installGiraph
setupGiraph
