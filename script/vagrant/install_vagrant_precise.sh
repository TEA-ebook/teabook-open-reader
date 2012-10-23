#!/bin/sh

# MongoDB 10gen                                                                                                        
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
sudo su -c "echo \"deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen\" > /etc/apt/sources.list.d/\
10gen.list"


# Update                                                                                                               
sudo apt-get -yqq update

# misc                                                                                                                 
sudo apt-get -yqq install make vim zlib1g-dev unzip git-core g++ libxslt-dev libxml2-dev optipng jpegoptim imagemagick\
 graphicsmagick libcurl4-gnutls-dev screen nginx

# MongoDB                                                                                                              
sudo apt-get -yqq install mongodb-10gen

# redis                                                                                                                
sudo apt-get -yqq install redis-server

# ruby                                                                                                                 
sudo apt-get -yqq install ruby1.9.3
# be sure ruby (and gem) 1.9 is the default.
# remove ruby1.8 or use update-alternatives

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
