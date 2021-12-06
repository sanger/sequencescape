FROM ruby:2.7.5-slim

# Install required software:
#  - net-tools: to run ping and other networking tools
#  - build-essential: to have a compiling environment for building gems
#  - curl: for healthcheck
#  - netcat: for wait for connection to database
#  - nodejs, yarn, git, default-libmysqlclient-dev and graphviz are rails gems dependencies
RUN apt-get update && apt-get install -y \
  net-tools build-essential curl netcat \
  nodejs yarn git default-libmysqlclient-dev npm graphviz

WORKDIR /code

COPY Gemfile /code
COPY Gemfile.lock /code

ADD . /code/

# TODO: We should get rid of this file if is not needed anymore
RUN cp /code/config/aker.yml.example /code/config/aker.yml

RUN npm install --global yarn
RUN gem install bundler
RUN bundle install
RUN bundle exec rails webpacker:install
