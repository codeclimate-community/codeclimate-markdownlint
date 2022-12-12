FROM ruby:2.7.7-alpine3.16

ENV LANG C.UTF-8

WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

RUN apk update && \
    apk add build-base git && \
    bundle && \
    apk del build-base

RUN adduser -u 9000 -D -g "app" app
COPY . /usr/src/app
RUN chown -R app:app /usr/src/app

USER app

RUN bundle exec rake docs:scrape

VOLUME /code
WORKDIR /code

CMD ["/usr/src/app/bin/codeclimate-markdownlint"]
