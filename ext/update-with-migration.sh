#!/bin/bash

ROOT=$PWD/..
RAILS_ENV=development

echo "Used Ruby = `which ruby`"

pushd $ROOT

  echo "==========Updating the sources=========="
  hg pull

  echo "==========Applying the last 10 migrations=========="
  hg log --template '{rev}\n' -l 10 db/migrate/* | sort | while read line
  do
    echo "==========Updating to revision $line=========="
    hg update -r ${line} -C 
    
    echo "==========Updating gems=========="
    bundle install --quiet

    echo "==========Migrating the database=========="
    rake db:migrate
  done

  echo "==========Updating to most recent revision=========="
  hg up default -C

  echo `hg id -in` > tmp/hg.rev

  echo "==========Restarting server=========="
  touch tmp/restart.txt

  echo
  sleep 5
  echo "Last 20 lines of server.log"
  tail -vn 20 log/$RAILS_ENV.log

popd

