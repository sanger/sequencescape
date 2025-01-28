ARG CHIPSET=default
ARG RUBY_VERSION=3.3.6
ARG APPLE_PLATFORM=linux/amd64

# Use the correct base image depending on the architecture
# For Apple M1 Chip, run: docker build --build-arg CHIPSET=m1 .
FROM ruby:${RUBY_VERSION}-slim AS base_default
FROM --platform=${APPLE_PLATFORM} ruby:${RUBY_VERSION}-slim AS base_m1
FROM base_${CHIPSET} AS base

COPY .nvmrc /.nvmrc

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
    netcat-traditional \
    nodejs \
    npm \
    ruby-dev \
    vim \
    wget \
    yarn

# switch shell to bash, to use source command
SHELL ["/bin/bash", "--login", "-i", "-c"]
# install nvm, in order to install the correct version of nodejs, rather than the image default
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
# install nodejs, using the version in the .nvmrc file
RUN source /root/.bashrc && nvm install
SHELL ["/bin/bash", "--login", "-c"]

WORKDIR /code

COPY Gemfile /code
COPY Gemfile.lock /code

ADD . /code/

# Install Chrome for being able to run tests
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN apt update
RUN apt install -y ./google-chrome-stable_current_amd64.deb
RUN rm ./google-chrome-stable_current_amd64.deb

# Rails installation
RUN npm install --global yarn
RUN gem install bundler
RUN bundle install
RUN yarn --install
