Sequencescape
=============

[![Build Status](https://travis-ci.org/sanger/sequencescape.svg?branch=next_release)](https://travis-ci.org/sanger/sequencescape)
[![Maintainability](https://api.codeclimate.com/v1/badges/2e3913c21e32b86511e4/maintainability)](https://codeclimate.com/github/sanger/sequencescape/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/2e3913c21e32b86511e4/test_coverage)](https://codeclimate.com/github/sanger/sequencescape/test_coverage)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](https://www.rubydoc.info/github/sanger/sequencescape)

Description
-----------

Sequencescape is a cloud based and highly extensible LIMS system for use in labs with
large numbers of samples.

 * Work order tracking
 * Sample and study management
 * Capacity management for pipelines
 * Accounting
 * Accessioning for samples and studies at the EBI ENA/EGA
 * Dynamically defined workflows for labs with support for custom processes
 * Labware and freezer tracking
 * API support for 3rd party applications

Current installation supports a million sampled and 1.3 million pieces
of labware and is used in a organisation of 900 people.


Getting started
---------------
It is strongly recommended that you use a ruby version manager such as RVM to
manage the Ruby version you are using.

It is strongly recommended that you use a ruby version manager such as RVM to
manage the Ruby version you are using. Sequencescape is developed using
ruby-2.5.1.

```
    $ cp config/aker.yml.example config/aker.yml
    $ $EDITOR config/config.yml
    $ gem install bundler
    $ bundle install
    $ bundle exec rake db:setup
    # The task below is optional, but creates an admin user account and a
    # few example studies and plates
    $ bundle exec rake working:setup
    $ bundle exec ./script/delayed_job start
    $ bundle exec rails s
    # Login as admin/admin
```


Data model
----------

```
 +--------+
 | Sample |                     +-------+
 +--------+                   _ | Study |
     |                      /   +-------+
 +-------+     +---------+ /    +---------+
 | Asset | --- | Request | -----| Project |
 +-------+     +---------+      +---------+
```

Delayed job
-----------

For background processing Sequencescape uses `delayed_job` to ensure
that the server is running.

```
$ bundle exec rake jobs:work
```

Supporting applications
-----------------------

There are a number of services that are needed in certain parts
of Sequencescape these are listed bellow.


Barcode printing
----------------

Barcode printing is carried out by a separate REST service, PrintMyBarcode. The source
for this is also available on GitHub [sanger/print\_my\_barcode](https://github.com/sanger/print_my_barcode)

Plate barcode service
---------------------

Due to DNA plate barcode series being stored in a legacy system
in Sanger your required to use a webservice for supplying numbers
for plates with a simple service.


Pico green
----------

To analyse Pico green plats you need for the pico green application.


Data warehousing
----------------

There is a client application for building a data warehouse based
on the information in Sequencescape. This is driven asynchronously via RabbitMQ.
See out various clients on GitHub:

[sanger/unified\_warehouse](https://github.com/sanger/unified_warehouse)

[sanger/event\_warehouse](https://github.com/sanger/event_warehouse)


Ruby warnings and rake 11
-------------------------

Rake 11 enables ruby warnings by default when running the test suite. These can
be disabled with `RUBYOPT='-W0'`, (eg. `RUBYOPT='-W0' bundle exec rake test`).
Currently these warnings are excessive, covering both our own code and external
dependencies. As it stands it makes the output of the test suite unusable in
travis, as it fills the buffer. These warning **will** need to be fixed, especially
in our own code.

NPG - Illumina tracking software
--------------------------------

For tracking illumina instruments you need the NPG systems.
NPG is linked to Sequencescape via a cluster formation batch
which represents a flowcell.

[NPG Software](http://www.sanger.ac.uk/resources/software/npg/)


Copyright (c) 2007, 2010-2019  Genome Research Ltd.
