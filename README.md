# rails-timeline-api

Ruby on Rails timeline API where users can create posts, comment on posts, and like both posts and comments.

## Features

- CRUD for timeline posts
- Comments on posts
- Likes and unlikes for posts and comments
- Pagination and sorting for the timeline feed
- Request and model specs with RSpec
- Local development with `docker compose`
- Simple browser demo for creating users, posts, comments, and likes
- Local Puma metrics endpoint

## Running locally

### With Docker

```bash
docker compose up --build web
```

Available endpoints:

- App and browser demo: [http://localhost:3000](http://localhost:3000)
- JSON API: [http://localhost:3000/api/v1/posts](http://localhost:3000/api/v1/posts)
- Puma metrics: [http://localhost:9393/metrics](http://localhost:9393/metrics)

The app runs `db:prepare` on boot, so the database is created and migrated automatically.

### Running tests

```bash
docker compose run --rm test bin/rails db:prepare RAILS_ENV=test
docker compose run --rm test bundle exec rspec
```

## Browser demo

- `/` lets you create users
- `/timeline` lets you create posts, upload an attachment from your computer, and like posts
- `/timeline/:id` shows a single post and lets you add comments

The browser flow uses a selected user from the UI so manual testing is easy without setting request headers by hand.

## API overview

### Timeline

`GET /api/v1/posts`

Supported query params:

- `page`
- `per_page`
- `sort`: `date` or `created_at`
- `direction`: `asc` or `desc`

Example:

```bash
curl "http://localhost:3000/api/v1/posts?page=1&per_page=10&sort=date&direction=desc"
```

### Posts

- `GET /api/v1/posts/:id`
- `POST /api/v1/posts`
- `PATCH /api/v1/posts/:id`
- `DELETE /api/v1/posts/:id`
- `POST /api/v1/posts/:id/like`
- `DELETE /api/v1/posts/:id/like`

### Comments

- `GET /api/v1/posts/:post_id/comments`
- `POST /api/v1/posts/:post_id/comments`
- `POST /api/v1/comments/:id/like`
- `DELETE /api/v1/comments/:id/like`

## Main technical choices

- Likes are polymorphic, so the same `likes` table is used for both posts and comments.
- Attachments are stored as post attachment records with a file type and URL.
- Browser uploads are saved locally for demo purposes.
- Authentication is intentionally simplified for this assignment.
- The browser demo is a thin layer on top of the JSON API to make manual review easier.

## Puma metrics

Prometheus-style Puma metrics are exposed locally at:

- [http://localhost:9393/metrics](http://localhost:9393/metrics)

Example:

```bash
curl http://localhost:9393/metrics
```
