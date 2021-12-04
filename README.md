# portal
Port of the official [ARP Networks](https://arpnetworks.com) [Portal](https://portal.arpnetworks.com) ~~to Rails 4~~

Now on Rails 6!

[![Build Status](https://travis-ci.org/arpnetworks/portal.svg?branch=master)](https://travis-ci.org/arpnetworks/portal)

Installation
------------

* Requirements

  - Git
  - Docker
  - Docker Compose

Quick Start::

  git clone git@github.com:arpnetworks/portal.git
  cd portal

  git checkout -b docker origin/docker

  cp .env-sample .env

  # IMPORTANT!
  # Change the stock passwords; best to use:
  #
  #   pwgen 10

  # Fill in the default salts with something different
  cp config/arp/password_encryption.yml.sample config/arp/password_encryption.yml

  cp config/arp/tender.yml.sample config/arp/tender.yml
  cp config/arp/globals.yml.sample config/arp/globals.yml
  cp config/arp/redis.yml.sample config/arp/redis.yml
  cp config/arp/hosts.yml.sample config/arp/hosts.yml

  cp lib/billing-system-models/lib/gateway.yml.example lib/billing-system-models/lib/gateway.yml
  cp lib/billing-system-models/lib/gpg.yml.example lib/billing-system-models/lib/gpg.yml

  cp config/database.yml.sample config/database.yml

  # Build stack and create initial DB
  docker-compose build
  docker-compose run web yarn install
  docker-compose run web rails db:setup

  # Run stack!
  docker-compose up

  Visit::

    http://localhost:3000

  or::

    http://localhost:3000/api/v1/internal/jobs/health

  Should return simply "OK"

  Testing
  -------

  Initialize::

    # Use the root password from your .env
    docker-compose exec db mysql -u root --password=<pass> -e 'create database powerdns_test'
    docker-compose exec db mysql -u root --password=<pass> powerdns_test < powerdns_test.sql

  You can run the full test suite with::

    docker-compose run web rspec

  For a more verbose output::

    docker-compose run web rspec --format doc

Copyright
---------

Copyright (c) 2008 - 2021 [ARP Networks, Inc.](https://arpnetworks.com)

