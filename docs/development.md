---
layout: page
title: Documentation - Development
ignore: true
---

# Development

## Environment variables

Environment variables required to run the application should be stored in an
`.env` file in `DEVELOPMENT` and `TEST` environments.

- Rails
  - `RAILS_MASTER_KEY`
    - DEVELOPMENT
    - TEST
    - PRODUCTION
  - `NEW_RELIC_APP_NAME`
    - PRODUCTION
  - `NEW_RELIC_LICENSE_KEY`
    - PRODUCTION
  - `NEW_RELIC_LOG`
    - PRODUCTION

- Google OAuth
  - `GOOGLE_CLIENT_ID`
    - DEVELOPMENT
    - PRODUCTION
  - `GOOGLE_CLIENT_SECRET`
    - DEVELOPMENT
    - PRODUCTION

- Twitter OAuth
  - `TWITTER_API_KEY`
    - DEVELOPMENT
    - PRODUCTION
  - `TWITTER_API_SECRET`
    - DEVELOPMENT
    - PRODUCTION

- Disqus OAuth
  - `DISQUS_PUBLIC_KEY`
    - DEVELOPMENT
    - PRODUCTION
  - `DISQUS_SECRET_KEY`
    - DEVELOPMENT
    - PRODUCTION

## Integrating Providers

- Integrate provider OAuth
- Create provider client
- Integrate client with account model
- Implement replying to tickets from provider

## Heroku

### Reset the database

After changing the schema in a way that's not migratable from the previous
state you need to reset the database.

- `heroku pg:reset DATABASE_URL`
- `heroku run rails db:migrate`
- `heroku restart`

## Docker

### Build

To build the respondo image run

```
docker build . --tag respondo
```

### Develop

To standup an instance of respondo for development purposes run

```
docker run -p 3000:3000 respondo
```

### Test

To run tests inside the docker container run

```
docker run respondo rspec --require rails_helper.rb
```

### CI

To update the CI docker image run:

- `docker build . --file Dockerfile.CI --tag matteeyah/respondo-ci:latest`
- `docker push matteeyah/respondo-ci:latest`

This is required when bumping the ruby version.