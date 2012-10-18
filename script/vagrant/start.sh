#!/bin/sh

cd teabook

# start resque
bundle exec rake resque:pool:start

# start thin
bundle exec thin start &

# start fake tea_api
bundle exec shotgun tea_api.ru -p 4567 &

cat <<EOF

4. if you want it, install an example of ebook
   (progit)
$ ./teabook/script/vagrant/addExample.sh

Connect to http://<vagrant ip>:3000

Enjoy!
EOF
