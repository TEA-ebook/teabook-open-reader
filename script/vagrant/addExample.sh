#!/bin/sh

cd teabook

# import epubs from examples/ebooks
wget -q -O examples/ebooks/progit.epub https://github.s3.amazonaws.com/media/progit.epub
bundle exec rake ebook:import:epub

cat <<EOF

Connect to http://<vagrant ip>:3000

Enjoy!
EOF
