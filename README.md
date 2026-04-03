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
- Small Turbo JS enhancement for post likes on the single-post browser page
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
- `/timeline` lets you create posts, upload an attachment from your computer, browse posts, paginate the list, and sort by newest or oldest
- `/timeline/:id` shows a single post and lets you update or delete your own post, like the post, add comments, and like comments

The browser flow uses a selected user from the UI so manual testing is easy without setting request headers by hand.

Post likes on the single-post page use a small Turbo JS enhancement, so the like button and counter update without a full page reload.

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
curl -H "X-User-Id: 1" "http://localhost:3000/api/v1/posts?page=1&per_page=10&sort=date&direction=desc"
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

## Authentication

Write actions use a simplified user context for this assignment.

- API requests can pass `X-User-Id: <id>`
- the browser demo uses a selected user from the UI
- some local browser/demo flows also pass `user_id` in the query string
- public read endpoints expose user names, but not email addresses

Example:

```bash
curl -H "X-User-Id: 1" \
  -H "Content-Type: application/json" \
  -d '{"post":{"date":"2026-03-31T12:00:00Z","description":"Launch timeline"}}' \
  http://localhost:3000/api/v1/posts
```

## Main technical choices

- Likes are polymorphic, so the same `likes` table is used for both posts and comments.
- Attachments are stored as post attachment records with a file type and URL.
- Browser uploads are saved locally for demo purposes.
- Authentication is intentionally simplified for this assignment by using a lightweight user context instead of a full sign-in flow.
- The browser demo is a thin layer on top of the JSON API to make manual review easier.
- Turbo JS is used in a minimal way to improve the browser demo without turning it into a separate frontend app.

## Puma metrics

Prometheus-style Puma metrics are exposed locally at:

- [http://localhost:9393/metrics](http://localhost:9393/metrics)

Example:

```bash
curl http://localhost:9393/metrics
```
