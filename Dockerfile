FROM ruby:2.7.5-slim

RUN apt-get update && apt-get install -y \
  net-tools build-essential curl \
  nodejs yarn git default-libmysqlclient-dev npm graphviz

WORKDIR /code

COPY Gemfile /code
COPY Gemfile.lock /code

ADD . /code/

RUN cp /code/config/aker.yml.example /code/config/aker.yml

RUN npm install --global yarn
RUN gem install bundler
RUN bundle install
RUN bundle exec rails webpacker:install
