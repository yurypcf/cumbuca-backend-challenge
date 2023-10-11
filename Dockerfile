# syntax=docker/dockerfile:1
FROM ruby:3.1.3

RUN apt-get update -qq && \
    apt-get install -y build-essential libvips && \
    apt-get clean && \
    apt-get install -y postgresql-client && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ENV RAILS_LOG_TO_STDOUT="1" \
    RAILS_ENV="development" \
    BUNDLE_WITHOUT="development"

COPY Gemfile* .

RUN bundle install

COPY . .

EXPOSE 3000
CMD ["bin/setup"]