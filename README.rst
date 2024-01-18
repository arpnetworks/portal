The official `ARP Networks`_ `Portal`_, now on Rails 6!

.. _ARP Networks: https://arpnetworks.com
.. _Portal: https://portal.arpnetworks.com

Installation
------------

* Requirements

  - Git
  - Docker
  - Docker Compose

Quick Start::

  git clone git@github.com:arpnetworks/portal.git
  cd portal

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

You can create a new account or see ``db/seeds.rb`` for some default accounts.

Also::

  http://localhost:3000/api/v1/internal/jobs/health

Should return simply ``OK``

Testing
-------

Initialize::

  # Use the root password from your .env
  docker-compose exec db mysql -u root --password=<pass> -e 'create database powerdns_test'
  docker-compose exec -T db mysql -u root --password=<pass> powerdns_test < powerdns_test.sql

You can run the full test suite with::

  docker-compose run web rspec

For a more verbose output::

  docker-compose run web rspec --format doc

To run our JavaScript specs::

  docker-compose run web yarn run jest spec/

But the following shortcut _may_ work if you have ``yarn`` installed locally::

  yarn run test

Selenium-based tests will fail, however.  To run the tests with Selenium /
Chrome visiting a local running copy of this app, do the following::

  # Starts a slightly modified docker container of the Portal, with Selenium Server / Chrome
  ./dev/docker start

  # Run rspec within this modified container
  ./dev/rspec

Stripe
------

It helps to have the Stripe CLI for developing and testing Stripe integration::

  # Download latest tarball from https://github.com/stripe/stripe-cli/releases/latest
  tar xzvf stripe_X.X.X_linux_x86_64.tar.gz
  mv ./stripe ~/some-place-in-your-PATH

Pair the CLI with your Stripe account::

  stripe login

Follow the instructions.

To forward events to your local environment::

  stripe listen --forward-to localhost:3000/api/v1/stripe/webhook

To trigger an event (example)::

  stripe trigger payment_intent.succeeded

To see all supported events::

  stripe trigger --help

Copyright
---------

Copyright (c) 2008 - 2024 `ARP Networks, Inc. <https://arpnetworks.com>`_
