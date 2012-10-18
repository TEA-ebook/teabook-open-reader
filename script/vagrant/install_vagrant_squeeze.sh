#!/bin/sh

sudo su -c "echo \"deb http://deb.bearstech.com/squeeze redis/\" > /etc/apt/sources.list.d/redis.list"
sudo su -c "echo \"deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen\" > /etc/apt/sources.list.d/10gen.list"
sudo su -c "echo \"deb http://deb.bearstech.com/squeeze ruby-1.9.3/\" > /etc/apt/sources.list.d/ruby1.9.3.list"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
sudo apt-get -yqq update
sudo apt-get -yqq --force-yes install make vim zlib1g-dev unzip git-core g++ libxslt-dev libxml2-dev optipng jpegoptim imagemagick graphicsmagick libcurl4-gnutls-dev screen redis-server mongodb-10gen ruby1.9.3 nginx
sudo apt-get -yqq remove ruby1.8

cd /home/vagrant

echo 'export GEM_HOME=~/gem' >> /home/vagrant/.bashrc
echo 'export PATH=~/bin:$GEM_HOME/bin:$PATH' >> /home/vagrant/.bashrc
export GEM_HOME=~/gem
export PATH=~/bin:$GEM_HOME/bin:$PATH

ln -s /vagrant teabook

cat <<EOF

System dependencies are installed.

Now you can install the teabook-open-reader:

1. connect to the vagrant vm
$ vagrant ssh
2. execute once the installation script
   this will install some project dependencies
   and configure the application (mongo, secret
   token)
$ ./teabook/script/vagrant/install.sh
3. start the server
$ ./teabook/script/vagrant/start.sh
4. if you want it, install an example of ebook
   (progit)
$ ./teabook/script/vagrant/addExample.sh

Connect to http://<vagrant ip>:3000

Enjoy!

EOF
