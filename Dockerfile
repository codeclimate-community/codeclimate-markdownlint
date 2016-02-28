FROM ruby:2.3.0-slim

ENV LANG C.UTF-8

WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

RUN apt-get update && \
    apt-get install -y build-essential && \
    bundle && \
    apt-get remove -y build-essential

RUN adduser --uid 9000 --disabled-password --quiet --gecos "app" app
COPY . /usr/src/app
RUN chown -R app:app /usr/src/app

USER app

RUN bundle exec rake docs:scrape

VOLUME /code
WORKDIR /code

CMD ["/usr/src/app/bin/codeclimate-markdownlint"]
