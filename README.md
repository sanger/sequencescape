# ![logo](https://github.com/sanger/sequencescape/raw/master/app/assets/images/sequencescape.gif) Sequencescape

![Ruby Test](https://github.com/sanger/sequencescape/workflows/Ruby%20Test/badge.svg)
![Javascript testing](https://github.com/sanger/sequencescape/workflows/Javascript%20testing/badge.svg)
![Linting](https://github.com/sanger/sequencescape/workflows/Linting/badge.svg)
[![Test Coverage](https://codecov.io/github/sanger/sequencescape/graph/badge.svg?token=Fsd7I0GYQf)](https://codecov.io/github/sanger/sequencescape)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](https://sanger.github.io/sequencescape/)
[![Knapsack Pro Parallel CI builds for RSpec Tests](https://img.shields.io/badge/Knapsack%20Pro-Parallel%20%2F%20RSpec%20Tests-%230074ff)](https://knapsackpro.com/dashboard/organizations/1976/projects/1324/test_suites/1880/builds?utm_campaign=organization-id-1976&utm_content=test-suite-id-1880&utm_medium=readme&utm_source=knapsack-pro-badge&utm_term=project-id-1324)
[![Knapsack Pro Parallel CI builds for Cucumber Tests](https://img.shields.io/badge/Knapsack%20Pro-Parallel%20%2F%20Cucumber%20Tests-%230074ff)](https://knapsackpro.com/dashboard/organizations/1976/projects/1324/test_suites/1881/builds?utm_campaign=organization-id-1976&utm_content=test-suite-id-1881&utm_medium=readme&utm_source=knapsack-pro-badge&utm_term=project-id-1324)

Sequencescape is a cloud based and highly extensible LIMS system for use in labs with large numbers
of samples.

- Work order tracking
- Sample and study management
- Capacity management for pipelines
- Accounting
- Accessioning for samples and studies at the EBI ENA/EGA
- Dynamically defined workflows for labs with support for custom processes
- Labware and freezer tracking
- API support for 3rd party applications

Current installation supports over 5 million samples and 1.8 million pieces of labware and is used in
a organisation of 900 people.

## Contents

<!-- toc -->

- [Documentation](#documentation)
  - [Linting](#linting)
- [Requirements](#requirements)
- [Getting started (using Docker)](#getting-started-using-docker)
- [Getting started (using native installation)](#getting-started-using-native-installation)
  - [Installing ruby](#installing-ruby)
    - [rbenv](#rbenv)
  - [Automatic Sequencescape setup](#automatic-sequencescape-setup)
  - [Manual Sequencescape setup](#manual-sequencescape-setup)
    - [Installing gems](#installing-gems)
    - [Adjusting config](#adjusting-config)
    - [Default setup](#default-setup)
  - [Starting rails](#starting-rails)
  - [Vite](#vite)
    - [Delayed job](#delayed-job)
  - [Message broker](#message-broker)
- [Testing](#testing)
- [Linting and formatting](#linting-and-formatting)
- [Rake tasks](#rake-tasks)
- [Supporting applications](#supporting-applications)
  - [Barcode printing](#barcode-printing)
  - [Plate barcode service](#plate-barcode-service)
  - [Data warehousing](#data-warehousing)
- [Miscellaneous](#miscellaneous)
  - [Lefthook](#lefthook)
  - [Ruby warnings and rake 11](#ruby-warnings-and-rake-11)
  - [NPG - Illumina tracking software](#npg---illumina-tracking-software)
  - [Troubleshooting](#troubleshooting)
    - [MySQL errors when installing](#mysql-errors-when-installing)
    - [MySQL errors after system updates](#mysql-errors-after-system-updates)
    - [Installing on Apple Silicon (M1)](#installing-on-apple-silicon-m1)
  - [API V2 Authentication](#api-v2-authentication)
  - [Publishing AMQP Messages](#publishing-amqp-messages)
  - [CI](#ci)
  - [ERD](#erd)
  - [Updating the table of contents](#updating-the-table-of-contents)

<!-- tocstop -->

## Documentation

The Yard documentation is also hosted at [GitHub Pages](https://pages.github.com/) under [https://sanger.github.io/sequencescape/](https://sanger.github.io/sequencescape/).
The documentation is automatically updated via a CI workflow when a merge to master occurs, but you can also trigger it manually against any branch (the branch can be selected using the "Run Workflow" button in the [corresponding action](https://github.com/sanger/sequencescape/actions/workflows/generate_pages.yml)).

To preview this documentation, you can spin up a yard server locally using the following command:

```shell
yard server --reload sequencescape .
```

You can then access the Sequencescape documentation through: [http://localhost:8808/docs](http://localhost:8808/docs)

If the server complains that the stack depth is too deep, this only appears to be a problem when you try to view the documentation without pre-compiling it.
Precompiling is the simple solution and can be achieved with the following.

```shell
yard doc
```

This will pre-fill the cache and allow the server command above to display the documentation without complaining about stack depths.

### Linting

Yard-Junk is used to check for missing or incorrect documentation. To run the checks:

```shell
bundle exec yard-junk --sanity
```

## Requirements

The following tools are required for development:

- ruby (version defined in the `.ruby-version`)
- yarn (`brew install yarn`)
- node (`brew install node@<version>` version defined in the `.nvmrc`, ensure node is in your PATH)
- mysql client libraries - if you do not want to install mysql server on your machine, consider
  using mysql-client: `brew install mysql-client`. Alternatively, to install the MySQL required by
  Sequencescape (currently 8.0)

## Getting started (using Docker)

To set up a local development environment in Docker, you have to build a new Docker image for
Sequencescape. start a stack of services that include a mysql database, and reset
this database contents. You can do all together by running the commands:

```shell
docker compose build
RESET_DATABASE=true docker compose up
```

Or if you are using an Apple M1 Chip:

```shell
docker compose build --build-arg CHIPSET=m1
USE_POLLING_FILE_WATCHER=true RESET_DATABASE=true docker compose up
```

Optionally, if this is not the first time you start the app, you may not want to reset the
database, and you can run this command instead:

```shell
docker compose up
```

With this we should have started Sequencescape server and all required services. You should be
able to access Sequencescape by going to <http://localhost:3000> and log in with
username and password admin/admin.

The envvar `PRECOMPILE_ASSETS` is also available as `PRECOMPILE_ASSETS=false docker compose up` which will avoid precompiling the assets as Sequencescape is started.

If you are using [Apple silicon](https://support.apple.com/en-gb/HT211814) and encounter any issues, please see [Troubleshooting](#installing-on-apple-silicon-m1) below.

**ABOUT LOCAL DEVELOPMENT SETUP** You may want to start only the required services for Sequencescape (server and jobs worker) and use your local version of Mysql
instead of the Docker version, in that case you can start this setup with the
command:

```shell
docker compose -f docker compose-dev.yml up
```

**ABOUT RECREATE DOCKER IMAGE** If you ever need to recreate the image built on first start (because you made modifications
to the Dockerfile file) you can run the building process again with:

```shell
docker compose build
```

## Getting started (using native installation)

This section only applies if you don't have Docker installed or if you prefer a native installation
of Sequencescape.

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

#### Adjusting config

The `config/database.yml` file saves the list of databases.

#### Default setup

1. Create the database tables

   ```shell
   bundle exec rake db:setup
   ```

2. Install webpacker and the required JS libraries

   ```shell
   yarn
   ```

### Starting rails

```shell
bundle exec rails s
```

Once setup, the default user/password is `admin/admin`.

### Vite

Ensure Node is installed, and in your PATH. You might need to run
`bin/vite build --clear --mode=development`

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
must have RabbitMQ installed. It may be easiest to use the docker image [https://hub.docker.com/\_/rabbitmq](https://hub.docker.com/_/rabbitmq).

`docker run -d --hostname my-rabbit --name some-rabbit -p 8080:15672 -p 5672:5672 rabbitmq:3-management`

It can be useful to follow the rabbitmq logs, to look for broken connections or other problems. To do this using the docker image,
get the container id using `docker ps`, and then:

`docker logs -f <container id>`

To start the consumer off listening for messages:

`bundle exec warren consumer start`

The consumer will run in the foreground, logging to the console. You can stop it with Ctrl-C.

For more warren actions, either use `bundle exec warren help` or see the
[warren documentation](https://rubydoc.info/gems/sanger_warren)

You will also have to change the config in config/warren.yml from `type: log` to `type: broadcast` to get
it to actually send messages in development mode.

## Testing

Testing is done in one of three ways; using rspec, via rails tests or with cucumber.

1. To run the rspec tests (found in `rspec/` dir.):

   ```shell
   bundle exec rspec --fail-fast [<path_to_spec>]
   ```

1. To run the rails tests (found in `tests/` dir.):

   ```shell
   bundle exec rake test -f
   ```

   For a single file:

   ```shell
   bundle exec ruby -Itest test/lib/label_printer/print_job_test.rb
   ```

1. To run cucumber tests (found in `features/` dir.) first ensure you have a `sequencescape_test_cuke` database configured by running:

   ```shell
   RAILS_ENV=cucumber bundle exec rake db:setup
   ```

   then run cucumber itself:

   ```shell
   bundle exec cucumber
   ```

For a single file:

```shell
bundle exec cucumber features/create_plates.feature
```

## Linting and formatting

Rubocop is used for linting.

```shell
bundle exec rubocop
```

Note that permanent `Exclude`s should be defined in `.rubocop.yml`, with 'temporary' ones
(automatically) listed in `.rubocop_todo.yml`.

To update `.rubocop_todo.yml`, execute

```shell
rubocop --auto-gen-config --no-exclude-limit
```

Prettier is used for formatting.

```shell
yarn prettier --check .
yarn prettier --write .
```

(If prettier is not yet installed, run `yarn`. This should have ben run in `bin/setup`)

- Prettier rules are configured in .prettierrc.json
- Whole files can be ignored in .prettierignore
- Sections of files can be disabled using #prettier-ignore

## Rake tasks

Rake tasks are available for specialised tasks as well as support tasks. Support tasks allow ease
of running standalone scripts multiple times.

A breakdown of the the available tasks and how to run them can be found [here](lib/tasks/README.md)

## Supporting applications

There are a number of services that are needed in certain parts of Sequencescape these are listed
below.

### Barcode printing

Barcode printing is carried out by a separate REST service, PrintMyBarcode. The source
for this is also available on GitHub [sanger/print_my_barcode](https://github.com/sanger/print_my_barcode)

### Plate barcode service

Due to DNA plate barcode series being stored in a legacy system in Sanger you are required to use a
webservice for supplying numbers for plates with a simple service.

### Data warehousing

There is a client application for building a data warehouse based on the information in
Sequencescape. This is driven asynchronously via RabbitMQ.

See our various clients on GitHub:

[sanger/unified_warehouse](https://github.com/sanger/unified_warehouse)

[sanger/event_warehouse](https://github.com/sanger/event_warehouse)

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

- If you are using homebrew with rbenv and run into errors relating to SSL, have a look [here](https://github.com/brianmario/mysql2/issues/795#issuecomment-433219176)

- If you are upgrading a homebrew MySQL locally and have an error about a missing libmysqlclient dylib file, you may need to redownload the mysql2 gem to fix it i.e. `bundle install --redownload`
  This is because the mysql2 gem is simlinked to the homebrew mysql.

- If bundle install is failing to install the `mysql2` gem, try the below (updating the paths as required):

```
gem install mysql2 -v '0.5.6' -- \
--with-mysql-lib=/opt/homebrew/Cellar/mysql/ \
--with-mysql-dir=/opt/homebrew/Cellar/mysql/9.0.1_1 \
--with-mysql-config=/opt/homebrew/Cellar/mysql/9.0.1_1/bin/mysql_config \
--with-mysql-include=/opt/homebrew/Cellar/mysql/9.0.1_1/include
```

#### MySQL errors after system updates

If you encounter a LoadError at dlopen call to mysql2 bundle because of a missing dynamic library, try the following command to update the cached gem.

```
gem pristine mysql2
```

#### Installing on Apple Silicon (M1)

If installation issues are encountered with Docker on M1 processors, try the fixes below:

- The docker compose build command fails with any mentions to a processor architecture ('amd64', 'x86') or the message below:

  ```sh
  ...
  #0 1.528 The following packages have unmet dependencies:
  #0 1.568  google-chrome-stable:amd64 : Depends: libasound2:amd64 (>= 1.0.17) but it is not installable
  #0 1.568                               Depends: libatk-bridge2.0-0:amd64 (>= 2.5.3) but it is not installable
  ...
  #0 1.568                               Depends: libxkbcommon0:amd64 (>= 0.5.0) but it is not installable
  #0 1.568                               Depends: libxrandr2:amd64 but it is not installable
  #0 1.581 E: Unable to correct problems, you have held broken packages.
  ------
  failed to solve: process "/bin/bash --login -c apt install -y ./google-chrome-stable_current_amd64.deb" did not complete successfully: exit code: 100
  ```

  Force docker to use the an AMD image as the base by setting `--build-arg CHIPSET=m1` during the build.
  It is also recommended to [install and enable Rosetta 2](https://docs.docker.com/desktop/install/mac-install/#mac-with-apple-silicon).

- The sequencescape_server container terminates with the error:

  ```sh
  Function not implemented - Failed to initialize inotify (Errno::ENOSYS)
  ```

  Use a polling instead of event file update checker by setting `USE_POLLING_FILE_WATCHER=true` during the compose up.

  [[GitHub issue](https://github.com/evilmartians/terraforming-rails/issues/34#issuecomment-872021786)]

### API V2

#### Authentication

The V2 API has had authentication checks added to it so that other applications calling the API should provide a valid key.
The key is passed by the client application via the `X-Sequencescape-Client-Id` header.
Keys can be generated via the Rail Console by creating new `ApiApplication` records and observing the `key` attribute on them.
As of the time of writing, there are three outcomes to a request made, with respect to API key submission:

- The client calls an API V2 endpoint with a valid API key in the header of the request.
  - The response given has a valid status code and the body contains the requested information/confirmation.
- The client calls an API V2 endpoint with an invalid API key in the header of the request.
  - The response given has status code 401 Unauthorized and contains a JSON body explaining that a valid API key must be provided for the header.
  - The request is logged with the prefix "Request made with invalid API key" including information about the client and the API key used.
- The client calls an API V2 endpoint without the API key header in the request.
  - The response is given as if a valid API key was provided.
  - The request is logged with the prefix "Request made without an API key" including information about the client.
  - The client application should be updated to use a valid API key in future.

#### Documentation

Example POST requests for all the Sequencscape API v2 resources are available to import into Postman REST Client.

The file `Sequencescape API v2.postman_collection.json` is stored in the Pipeline Solutions Shared Network Drive (Finder > Go > Connect to Server > `smb://files-smb/pipeline_solutions`)

### Publishing AMQP Messages

Some API endpoints (such as `/api/v2/bioscan/export_pool_xp_to_traction`) trigger background jobs which are responsible for publishing data to another instance of RabbitMQ.
In the case of the Bioscan Export Pool XP to Traction job, the message goes to the ISG managed RabbitMQ instance.
In order to publish a message, the job must get a schema from a registry.
Under development conditions, you may not have a registry running, hence the default config directs to the UAT instance of PSD's supported RedPanda.
This means, the first time you publish a message with this schema, you need to be connected to the Sanger network directly or via VPN.
After the first use, a cached file will be created in `data/avro_schema_cache` so that the registry does not need to be reachable to continue generating messages.

Because this is the first and only job doing this pubishing / RedPanda caching / Avro encoding, etc, there are parts which could be extracted in future if further jobs of this type are created.
This isn't necessary at this stage, but it seems wise to note the intended pattern of usage here for future work.

### CI

The GH actions builds use the Knapsack-pro gem to reduce build time by parallelizing the RSpec and Cucumber tests. There is no need to regenerate the knapsack_rspec_report.json file, Knapsack Pro will dynamically allocate tests to ensure tests finish as close together as possible.

### ERD

You can create a database entity relationship diagram, by specifying the title and attributes optionally, and view the output:

```
bundle exec rake erd title='Sequencescape Entity Relationship Diagram' attributes='primary_keys,foreign_keys,inheritance' orientation=horizontal polymorphism=true notation=bachman indirect=false inheritance=true only='Sample,Study,AliquotIndex,Aliquot,Project,Order,Submission,Labware,Receptacle,Request,Request::Metadata,Batch,BatchRequest,LabEvent,RequestType,Pipeline,SampleManifest,Sample::Metadata,Study::Metadata,Item,BaitLibrary,RequestEvent,Project::Metadata,Barcode,Purpose,QCResult,QCAssay,User,Plate,Tube,Well' exclude='Target,Commentable,Failable,Eventful,Eventable,Resource,Attributable,Owner,Authorizable,Documentable'

open erd.pdf
```

The command uses the [rails-erd](https://github.com/voormedia/rails-erd) gem.

### Updating the table of contents

To update the table of contents after adding things to this README you can use the [markdown-toc](https://github.com/jonschlinkert/markdown-toc)
node module. To install it, make sure you have installed the dev dependencies from yarn. To update
the table of contents, run:

```shell
npx markdown-toc -i README.md --bullets "-"
```

Copyright (c) 2007, 2010-2024 Genome Research Ltd.
