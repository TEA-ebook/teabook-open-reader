#!/bin/sh

cd ~

gem install bundle

cd teabook

bundle install

# copy default development configuration
cp config/mongoid/development.yml config/mongoid.yml

# generate a secret
SECRET=`bundle exec rake secret`
# put it in config/initializers/secret_token.rb
cp config/initializers/secret_token.rb.dist config/initializers/secret_token.rb
sed -i "s/Tea::Application.config.secret_token.*/Tea::Application.config.secret_token = \'$SECRET\'/" config/initializers/secret_token.rb

# create the default bookseller
bundle exec rake db:seed

cat <<EOF

3. start the server
$ ./teabook/script/vagrant/start.sh
4. if you want it, install an example of ebook
   (progit)
$ ./teabook/script/vagrant/addExample.sh

Connect to http://<vagrant ip>:3000

Enjoy!
EOF
