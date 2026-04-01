# Timeline API

Ruby on Rails API for a timeline where users can create posts, add comments, and like both posts and comments.

## Implemented features

- CRUD for timeline posts
- Post comments listing and creation
- Likes and unlikes for posts and comments
- Pagination and sorting for the timeline feed
- RSpec model and request specs
- Local development with `docker compose`

## Domain model

### User

- `name`
- `email`

### Post

- `date`
- `description`
- `attachments`

Attachments are represented as `post_attachments` records with:

- `file_type`: `photo`, `video`, or `pdf`
- `url`

This keeps the API simple and fulfills the timeline requirement without implementing binary upload storage. Actual file upload handling is intentionally left out because it was marked as a bonus.

### Comment

- belongs to a post
- belongs to a user
- contains `body`

### Like

- polymorphic like target
- can belong to either a `Post` or a `Comment`
- one like per user per target

## Authentication assumption

The repository did not include an authentication system, so the API uses a lightweight request header for user context:

- `X-User-Id: <user_id>`

Every API request must include a valid existing user ID in that header.

## API overview

### Timeline

`GET /api/v1/posts`

Query params:

- `page` default: `1`
- `per_page` default: `10`, max: `50`
- `sort` allowed: `date`, `created_at`
- `direction` allowed: `asc`, `desc`

Example:

```bash
curl -H "X-User-Id: 1" "http://localhost:3000/api/v1/posts?sort=date&direction=desc&page=1&per_page=5"
```

### Posts

- `GET /api/v1/posts/:id`
- `POST /api/v1/posts`
- `PATCH /api/v1/posts/:id`
- `DELETE /api/v1/posts/:id`
- `POST /api/v1/posts/:id/like`
- `DELETE /api/v1/posts/:id/like`

Create/update payload example:

```json
{
  "post": {
    "date": "2026-03-31T12:00:00Z",
    "description": "Launch timeline",
    "post_attachments_attributes": [
      { "file_type": "photo", "url": "https://cdn.example.com/photo.jpg" },
      { "file_type": "pdf", "url": "https://cdn.example.com/brief.pdf" }
    ]
  }
}
```

### Comments

- `GET /api/v1/posts/:post_id/comments`
- `POST /api/v1/posts/:post_id/comments`
- `POST /api/v1/comments/:id/like`
- `DELETE /api/v1/comments/:id/like`

Create comment payload:

```json
{
  "comment": {
    "body": "Nice update"
  }
}
```

## Running locally with Docker Compose

### Start the application

```bash
docker compose up --build web
```

The API will be available at [http://localhost:3000](http://localhost:3000).

The container entrypoint runs `db:prepare`, so the database is created and migrated automatically on boot.

### Run the test suite

```bash
docker compose run --rm test
```

If you want the PostgreSQL container to stay up in the background:

```bash
docker compose up -d db
docker compose run --rm test
```

## Running locally without Docker

If you already have Ruby 3.4.x and PostgreSQL installed:

```bash
bundle install
bin/rails db:prepare
bundle exec rspec
bin/rails server
```

## Choices made

### 1. Simple user context instead of full authentication

The assignment focuses on timeline behavior, not sign-in flows, so I used `X-User-Id` to keep the API testable and explicit.

### 2. Polymorphic likes

This avoids duplicated `post_likes` and `comment_likes` tables and keeps the code extensible.

### 3. Attachment metadata instead of upload infrastructure

Because uploading attachments was a bonus, I modeled attachments as URLs plus type metadata. This still supports photos, videos, and PDFs in the post payloads while keeping the implementation lean.

### 4. Request specs over controller specs

The assignment asked for unit and integration/request tests, so the request layer is covered directly, and model specs validate relationships and rules.

## Suggested pull request description

### What I changed

- implemented timeline post CRUD endpoints
- added comments and polymorphic likes
- added pagination and sorting
- added RSpec model and request coverage
- added Docker Compose setup for local development and test execution
- documented the API contract and key technical decisions

### Steps I took

1. Reviewed the generated Rails skeleton and existing routes/spec placeholders.
2. Added the missing data model: comments, likes, and attachment metadata.
3. Implemented JSON API endpoints for posts, comments, and likes.
4. Added validations, associations, and sorting/pagination behavior.
5. Wrote model specs and request specs for the main user flows.
6. Updated Docker configuration so the app can run locally with `docker compose`.
7. Rewrote the README with setup instructions, API examples, and design choices.
# rails-timeline-api
