FROM ruby:2.7.5-slim

RUN apt update && apt install -y build-essential nodejs yarn git default-libmysqlclient-dev
#RUN apt update && apt upgrade
# RUN apk update \
# && apk upgrade \
# && apk add --update --no-cache \
# build-base curl-dev mysql-dev \
# yaml-dev zlib-dev nodejs yarn git

WORKDIR /code

#RUN ["rbenv", "install"]

COPY Gemfile /code
COPY Gemfile.lock /code

ADD . /code/

RUN gem install bundler
RUN bundle install

EXPOSE 3000
CMD ["bundle", "exec", "rails", "s"]

