FROM ruby:2.7.6-slim

# Install required software:
#  - net-tools: to run ping and other networking tools
#  - build-essential: to have a compiling environment for building gems
#  - curl: for healthcheck
#  - netcat: for wait for connection to database
#  - nodejs, yarn, git, default-libmysqlclient-dev and graphviz are rails gems dependencies
RUN apt-get update && apt-get install -y \
build-essential \
curl \
default-libmysqlclient-dev \
git \
graphviz \
net-tools \
netcat \
nodejs \
npm \
vim \
wget \
yarn

WORKDIR /code

COPY Gemfile /code
COPY Gemfile.lock /code

ADD . /code/

# Install Chrome for being able to run tests
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN apt install -y ./google-chrome-stable_current_amd64.deb
RUN rm ./google-chrome-stable_current_amd64.deb

# Rails installation
RUN npm install --global yarn
RUN gem install bundler
RUN bundle install
RUN yarn --install
