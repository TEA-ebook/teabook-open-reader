TeaBook Open Reader
===================


> The TeaBook Open Reader is our long-term vision of how e-books will be read on
> PCs and tablets. Rather than creating a native application for every device
> and operating system version, we aim to develop a single reading application
> that can be used on a recent browser without any installation requirements.
> 
> Because our vision is to share rather than lock in our readers, we are sharing
> what we have developed. We hope you will take part in improving it and passing
> it on to others who can appropriate it.

Éric, on behalf of everyone at [TEA the e-book alternative][tea]


**TOC**


* The application
* Development status
* Distribution
* Technical details
 * Requirements (debian squeeze and ubuntu 12.04)
 * Installation from scratch
 * Installation with vagrant (debian squeeze and ubuntu 12.04)
 * Specs

The application  
---------------

The main objective of the application is to display e-books and offer readers
a pleasant reading environment. Because not everyone is online all the time,
users can download books and read them offline without any prior installation.

Books are accessed from the library screen. The library is the main window
where users will see their books displayed on a bookshelf with the title and
front cover image. A small icon will take them to the book’s back-cover blurb
and information on the publishing house, collection and author. In the same
interface, readers can download the book for offline reading.

The reader itself is accessed by touching the front cover of a book. The book
opens in full-screen and turns to the last page read. On the "reader"
interface, only the text itself is visible, along with two icons on the right
and left for turning pages. A menu (top) and a progress bar (bottom) appear
upon touching the tactile screen or clicking the mouse. From the menu, users
can access the contents, and in future, bookmarks and annotations. They can
also use the menu to configure the appearance of the reader and font size. The
progress bar displays the pagination and makes it easy to move from page to
page or chapter to chapter. A circle on the progress bar displays chapter
breaks, making it easy for readers to find their way around.

Our aim is to display the books as they were published. The visual appearance
of titles, fonts and formatting are therefore those of the publishers. We have
only integrated the modifications necessary for web-based reading and user
comfort (e.g. font size manager).

We are initially concentrating on the reading experience itself. Other social
functionalities are on the cards for future developments.

Development status 
------------------

A demo application is available at <http://demo-open-reader.tea-ebook.com/> 
presenting a handful of books that are in the public domain. Its
purpose is to give you an idea of the version we are actively developing; it
is not a final version. There are a number of anomalies left, and certain
functionalities are missing. Please let us know of any anomalies you notice.
Better still, if you contact us to participate in improving the reader, we
will help you access the source code so that you can make changes yourself.
Similarly, the app is currently only compatible with Chrome and the iPad. One
of our top priorities is to support all recent browsers, and our architecture
was chosen with this in mind. Mozilla’s strategy with
[Firefox's MarketPlace][firefox marketplace],
for instance, is clearly in line with our vision. Supporting Mozilla Firefox
is therefore a priority. One of the problems we are facing at the moment is
performance issues in adding content via data: URIs. We would be delighted if
you would like to work on inter-browser compatibility.

For the content, we have chosen to focus essentially on e-books in the
standard EPUB format. Version 2 is almost ready to go. Certain key version 3
functionalities, such as fixed layout, are already supported, but a lot of
work still needs to be done on the finer details, and on embedded Javascript.


Distribution 
------------

This application is a long-term project which we will continue to develop
indefinitely. We encourage you to join in and make your ideas for improvements
and priorities heard so that we can together design an application open to
everyone.

If you would like to contribute, please contact us for information on anything
not yet documented or to find out how a particular aspect functions.

The application itself is shared using the [GPL 3.0 license][license] with a
[specific exception][exception] for technical protection measures when required
by publishers. This licence gives you extensive rights, but you must comply with
certain requirements, for instance if you wish to distribute the application to
third parties. Please consult the licence content if you are not familiar with it.

We have shared a strategic application with the public. We hope that you will
do your part by contributing your changes and improvements. Working in this
manner will be of benefit to us all.

Please note that the application's name and certain parts of its original
design are not covered by the licence. This is so that you can personalise the
application with your own design.


Technical details 
-----------------

The software code is divided into two parts – the reader is written
essentially with CoffeeScript, while the server was built with Ruby, so as to
be able to analyse and prepare books for viewing on the reader.

Ruby-dependent code is indicated in the source code. The CoffeeScript section
just requires a browser once compiled in JavaScript.

### Requirements

* Redis
* MongoDB
* Ruby 1.9.3
* Unzip
* [Optipng][] and [jpegoptim][]
* bundler

#### Debian squeeze

Instructions on a Debian Squeeze, using bearstech and mongo repositories :

```sh
sudo su -c "echo \"deb http://deb.bearstech.com/squeeze redis/\" > /etc/apt/sources.list.d/redis.list"
sudo su -c "echo \"deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen\" > /etc/apt/sources.list.d/10gen.list"
sudo su -c "echo \"deb http://deb.bearstech.com/squeeze ruby-1.9.3/\" > /etc/apt/sources.list.d/ruby1.9.3.list"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
sudo apt-get -yqq update
sudo apt-get -yqq --force-yes install make vim zlib1g-dev unzip git-core g++ libxslt-dev libxml2-dev optipng jpegoptim imagemagick graphicsmagick libcurl4-gnutls-dev screen redis-server mongodb-10gen ruby1.9.3 nginx
sudo apt-get -yqq remove ruby1.8
```

#### Ubuntu 12.04 precise

```sh
# MongoDB 10gen
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
sudo su -c "echo \"deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen\" > /etc/apt/sources.list.d/10gen.list"
sudo apt-get -yqq update
sudo apt-get -yqq install make vim zlib1g-dev unzip git-core g++ libxslt-dev libxml2-dev optipng jpegoptim imagemagick graphicsmagick libcurl4-gnutls-dev screen nginx mongodb-10gen redis-server ruby1.9.3
# be sure ruby (and gem) 1.9 is the default.
# remove ruby1.8 or use update-alternatives
```

Install bundler

```sh
gem install bundle
```

### Installation from scratch

#### Application dependencies

Install/update dependencies with bundle :

```sh
bundle install
```

#### Mongo

Copy the mongodb configuration file and edit it if needed

```sh
cp config/mongoid/development.yml config/mongoid.yml
```

Alternatively you can execute the rails task :

```sh
bundle exec rails g mongoid:config
```

#### Secret

Generate a secret with `bundle exec rake secret` and copy it in `config/initializers/secret_token.rb`

```sh
# generate a secret
SECRET=`bundle exec rake secret`
# put it in config/initializers/secret_token.rb
cp config/initializers/secret_token.rb.dist config/initializers/secret_token.rb
sed -i "s/Tea::Application.config.secret_token.*/Tea::Application.config.secret_token = \'$SECRET\'/" config/initializers/secret_token.rb
```

#### Insert default datas in database

```sh
bundle exec rake db:seed
```

#### Start resque workers

This is used to convert epub to html.

```sh
bundle exec rake resque:pool:start
```

#### Start web server (thin)

```sh
bundle exec thin start
```

or use the rails task:

```sh
bundle exec rails s
```

#### Run the fake API

The accounts are configured in an other server. The authentication is also in this server.
This server is not open source. You can find informations about the API [here][api].

To be able to test the reader, a fake API exists. When executing it, authentication is always ok.

```sh
bundle exec shotgun tea_api.ru -p 4567
```

or, without code reloading

```sh
bundle exec thin -R tea_api.ru start -p 4567
```

### Installation with vagrant

This is the easier way to run TeaBook Open Reader.
Instructions can be found in the commit e9e528e870

You need to have [VirtualBox][] and [vagrant][] installed.

1 - get the sources

```sh
git clone git@github.com:TEA-ebook/teabook-open-reader.git
```

2 - got to `script/vagrant`

```sh
cd script/vagrant
```

3 - copy the `Vagrantfile` and edit it (ip, memory of cpu configuration, nfs share)

If you want a debian squeeze:

```sh
cp Vagrantfile_squeeze.dist Vagrantfile
vi Vagrantfile
```

and if you want an ubuntu 12.04:

```sh
cp Vagrantfile_precise.dist Vagrantfile
vi Vagrantfile
```

4 - run the vagrant. It will download the base box and execute the installation script

```sh
vagrant up
```

5 - follow instructions

```sh
vagrant ssh
./teabook/script/vagrant/install.sh
./teabook/script/vagrant/start.sh
```

6 - if you want, install an example book (optional)

```sh
./teabook/script/vagrant/addExample.sh
```

7 - open your browser on `http://<vm ip>:3000`


### Specs

Guard (Ruby+Javascript)

    bundle exec guard

Ruby only

    bundle exec rspec

Javascript only (in browser)

    RAILS_ENV=test bundle exec rake jasmine

Javascript only (headless)

    bundle exec jasmine-headless-webkit

[tea]: http://www.tea-ebook.com/ "TEA the e-book alternative"
[firefox marketplaceMarketPlace Firefox]: https://marketplace.mozilla.org/ "Firefox's MarketPlace"
[license]: http://www.gnu.org/licences/gpl-3.0.en.html "GPL 3.0 license"
[exception]: https://github.com/TEA-ebook/teabook-open-reader/blob/master/GPL-3-EXCEPTION "specific exception"
[Optipng]: http://optipng.sourceforge.net/ "Optipng"
[jpegoptim]: http://www.kokkonen.net/tjko/projects.html "JpegOptim"
[api]: https://github.com/TEA-ebook/teabook-open-reader/wiki/Api "API"
[VirtualBox]: https://www.virtualbox.org/ "VirtualBox"
[vagrant]: http://vagrantup.com/ "Vagrant"

