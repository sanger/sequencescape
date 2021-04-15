# ![logo](https://github.com/sanger/sequencescape/raw/master/app/assets/images/sequencescape.gif) Sequencescape

![Ruby Test](https://github.com/sanger/sequencescape/workflows/Ruby%20Test/badge.svg)
![Javascript testing](https://github.com/sanger/sequencescape/workflows/Javascript%20testing/badge.svg)
![Linting](https://github.com/sanger/sequencescape/workflows/Linting/badge.svg)
[![Maintainability](https://api.codeclimate.com/v1/badges/2e3913c21e32b86511e4/maintainability)](https://codeclimate.com/github/sanger/sequencescape/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/2e3913c21e32b86511e4/test_coverage)](https://codeclimate.com/github/sanger/sequencescape/test_coverage)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](https://www.rubydoc.info/github/sanger/sequencescape)
[![Knapsack Pro Parallel CI builds for RSpec Tests](https://img.shields.io/badge/Knapsack%20Pro-Parallel%20%2F%20RSpec%20Tests-%230074ff)](https://knapsackpro.com/dashboard/organizations/1976/projects/1324/test_suites/1880/builds?utm_campaign=organization-id-1976&utm_content=test-suite-id-1880&utm_medium=readme&utm_source=knapsack-pro-badge&utm_term=project-id-1324)
[![Knapsack Pro Parallel CI builds for Cucumber Tests](https://img.shields.io/badge/Knapsack%20Pro-Parallel%20%2F%20Cucumber%20Tests-%230074ff)](https://knapsackpro.com/dashboard/organizations/1976/projects/1324/test_suites/1881/builds?utm_campaign=organization-id-1976&utm_content=test-suite-id-1881&utm_medium=readme&utm_source=knapsack-pro-badge&utm_term=project-id-1324)

Sequencescape is a cloud based and highly extensible LIMS system for use in labs with large numbers
of samples.

* Work order tracking
* Sample and study management
* Capacity management for pipelines
* Accounting
* Accessioning for samples and studies at the EBI ENA/EGA
* Dynamically defined workflows for labs with support for custom processes
* Labware and freezer tracking
* API support for 3rd party applications

Current installation supports over 5 million samples and 1.8 million pieces of labware and is used in
a organisation of 900 people.

## Contents

<!-- toc -->

* [Documentation](#documentation)
* [Requirements](#requirements)
* [Getting started](#getting-started)
  * [Installing ruby](#installing-ruby)
    * [rbenv](#rbenv)
  * [Automatic Sequencescape setup](#automatic-sequencescape-setup)
  * [Manual Sequencescape setup](#manual-sequencescape-setup)
    * [Installing gems](#installing-gems)
    * [Adjusting config](#adjusting-config)
    * [Default setup](#default-setup)
  * [Stating rails](#stating-rails)
    * [Delayed job](#delayed-job)
* [Testing](#testing)
* [Rake tasks](#rake-tasks)
* [Supporting applications](#supporting-applications)
  * [Barcode printing](#barcode-printing)
  * [Plate barcode service](#plate-barcode-service)
  * [Data warehousing](#data-warehousing)
* [Miscellaneous](#miscellaneous)
  * [Ruby warnings and rake 11](#ruby-warnings-and-rake-11)
  * [NPG - Illumina tracking software](#npg---illumina-tracking-software)
  * [Troubleshooting](#troubleshooting)
    * [MySQL errors when installing](#mysql-errors-when-installing)
  * [Updating the table of contents](#updating-the-table-of-contents)
  * [CI](#ci)

<!-- tocstop -->

## Documentation

In addition to the [externally hosted YARD docs](https://www.rubydoc.info/github/sanger/sequencescape), you can also run a local server:

```shell
yard server -r --gems -m sequencescape .
```

You can then access the Sequencescape documentation through: http://localhost:8808/docs/sequencescape
Yard will also try and document the installed gems: http://localhost:8808/docs

## Requirements

The following tools are required for development:

* ruby (version defined in the `.ruby-version`)
* yarn
* node (version defined in the `.nvmrc`)
* mysql client libraries - if you do not want to install mysql server on your machine, consider
using mysql-client: `brew install mysql-client`. Alternatively, to install the MySQL required by
Sequencescape (currently 5.7) use [this](https://gist.github.com/operatino/392614486ce4421063b9dece4dfe6c21)
helpful link.

## Getting started

### Installing ruby

It is strongly recommended that you use a ruby version manager such as RVM or rbenv to manage the
Ruby version you are using. The ruby version required should be found in `.ruby-version`.

#### rbenv

If you have the [rbenv ruby-build plugin](https://github.com/rbenv/ruby-build) it is as simple as:

`rbenv install`

It will pick up the version from the .ruby-version file automatically

### Automatic Sequencescape setup

To automatically install the required gems, set-up default configuration files, and set up your database run:

```shell
bin/setup
```

### Manual Sequencescape setup

In the event you have trouble with the automatic process, you may wish to step through the various steps manually.

#### Installing gems

[Bundler](https://bundler.io) is used to install the required gems:

```shell
gem install bundler
bundle install
```

If you experience `An error occurred while installing ruby-oci8` then disable the oracle gem installation:

```shell
bundle config without warehouse
```

The oracle adapters are not needed for development.

#### Adjusting config

Copy the `config/aker.example.yml` file to `config/aker.example.yml`.

The `config/database.yml` file saves the list of databases.

#### Default setup

1. Create the database tables

    ```shell
    bundle exec rake db:setup
    ```

2. Install webpacker and the required JS libraries

    ```shell
    bundle exec rails webpacker:install
    ```

### Stating rails

```shell
bundle exec rails s
```

Once setup, the default user/password is `admin/admin`.

#### Delayed job

For background processing Sequencescape uses `delayed_job` to ensure that the server is running. It
is strongly recommended to start one for Sequencescape to behave as expected.

```shell
bundle exec rake jobs:work
```

OR

```shell
bundle exec ./script/delayed_job start
```

### Message broker

Sequencescape has its own message broker and consumer. To develop this or run it locally, you
must have RabbitMQ installed. It may be easiest to use the docker image (https://hub.docker.com/_/rabbitmq).

```docker run -d --hostname my-rabbit --name some-rabbit -p 8080:15672 -p 5672:5672 rabbitmq:3-management```

It can be useful to follow the rabbitmq logs, to look for broken connections or other problems. To do this using the docker image,
get the container id using `docker ps`, and then:

```docker logs -f <container id>```

To start the consumer off listening for messages:

```bundle exec ./bin/amqp_client start```

where `start` instructs it to start. You can also stop a worker by calling `stop`
or restart it with `restart`.

Logs can be found in `tmp/pids`.

You will also have to change the config in config/warren.yml from `type: log` to `type: broadcast` to get
it to actually send messages in development mode.


## Testing

Testing is done in three ways; using rspec, rails test and feature tests.

1. To run the rspec tests (found in `rspec/` dir.):

    ```shell
    bundle exec rspec --fail-fast [<path_to_spec>]
    ```

1. To run the rails tests (found in `tests/` dir.):

    ```shell
    bundle exec rake test -f
    ```

## Rake tasks

Rake tasks are available for specialised tasks as well as support tasks. Support tasks allow ease
of running standalone scripts multiple times.

A breakdown of the the available tasks and how to run them can be found [here](lib/tasks/README.md)

## Supporting applications

There are a number of services that are needed in certain parts of Sequencescape these are listed
below.

### Barcode printing

Barcode printing is carried out by a separate REST service, PrintMyBarcode. The source
for this is also available on GitHub [sanger/print\_my\_barcode](https://github.com/sanger/print_my_barcode)

### Plate barcode service

Due to DNA plate barcode series being stored in a legacy system in Sanger you are required to use a
webservice for supplying numbers for plates with a simple service.

### Data warehousing

There is a client application for building a data warehouse based on the information in
Sequencescape. This is driven asynchronously via RabbitMQ.

See our various clients on GitHub:

[sanger/unified\_warehouse](https://github.com/sanger/unified_warehouse)

[sanger/event\_warehouse](https://github.com/sanger/event_warehouse)

## Miscellaneous

### Lefthook

[Lefthook](https://github.com/Arkweid/lefthook) is a git-hook manager that will
ensure staged files are linted before committing.

You can install it either via homebrew `brew install Arkweid/lefthook/lefthook` or rubygems `gem install lefthook`

You'll then need to initialize it for each repository you wish to track `lefthook install`

Hooks will run automatically on commit, but you can test them with: `lefthook run pre-commit`

In addition you can also run `lefthook run fix` to run the auto-fixers on staged files only.
Note that after doing this you will still need to stage the fixes before committing. I'd love to be
able to automate this, but haven't discovered a solution that maintains the ability to partially
stage a file, and doesn't involve running the linters directly on files in the .git folder.

### Ruby warnings and rake 11

Rake 11 enables ruby warnings by default when running the test suite. These can be disabled with
`RUBYOPT='-W0'`, (eg. `RUBYOPT='-W0' bundle exec rake test`).

Currently these warnings are excessive, covering both our own code and external dependencies. As it
stands it makes the output of the test suite unusable in travis, as it fills the buffer. These
warnings **will** need to be fixed, especially in our own code.

### NPG - Illumina tracking software

For tracking illumina instruments you need the NPG systems. NPG is linked to Sequencescape via a
cluster formation batch which represents a flowcell.

[NPG Software](http://www.sanger.ac.uk/resources/software/npg/)

### Troubleshooting

#### MySQL errors when installing

If you are using homebrew with rbenv and run into errors relating to SSL, have a look [here](https://github.com/brianmario/mysql2/issues/795#issuecomment-433219176)

### Updating the table of contents

To update the table of contents after adding things to this README you can use the [markdown-toc](https://github.com/jonschlinkert/markdown-toc)
node module. To install it, make sure you have install the dev dependencies from yarn. To update
the table of contents, run:

```shell
yarn markdown-toc -i README.md --bullets "*"
```

### CI

The GH actions builds use the Knapsack-pro gem to reduce build time by parallelizing the RSpec and Cucumber tests. There is no need to regenerate the knapsack_rspec_report.json file, Knapsack Pro will dynamically allocate tests to ensure tests finish as close together as possible.

Copyright (c) 2007, 2010-2021  Genome Research Ltd.
