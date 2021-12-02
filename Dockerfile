FROM ruby:2.7.5-slim

RUN apt update && apt install -y build-essential nodejs yarn git default-libmysqlclient-dev

WORKDIR /code

COPY Gemfile /code
COPY Gemfile.lock /code

ADD . /code/

RUN gem install bundler
RUN bundle install

EXPOSE 3000
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]

