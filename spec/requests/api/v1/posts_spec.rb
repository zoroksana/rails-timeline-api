require 'rails_helper'

RSpec.describe "Api::V1::Posts", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "X-User-Id" => user.id.to_s } }

  describe "GET /api/v1/posts" do
    let!(:oldest_post) { create(:post, description: "oldest", date: Time.zone.parse("2026-03-28 10:00:00")) }
    let!(:middle_post) { create(:post, description: "middle", date: Time.zone.parse("2026-03-29 10:00:00")) }
    let!(:newest_post) { create(:post, description: "newest", date: Time.zone.parse("2026-03-30 10:00:00")) }

    it "returns paginated timeline entries sorted by date descending by default" do
      get api_v1_posts_path, params: { per_page: 2 }, headers: headers

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)

      expect(payload.dig("data", 0, "description")).to eq("newest")
      expect(payload.dig("data", 1, "description")).to eq("middle")
      expect(payload.dig("meta", "total_count")).to eq(3)
      expect(payload.dig("meta", "total_pages")).to eq(2)
    end

    it "supports custom sorting" do
      get api_v1_posts_path, params: { sort: "date", direction: "asc" }, headers: headers

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)

      expect(payload.dig("data", 0, "description")).to eq("oldest")
      expect(payload.dig("data", 2, "description")).to eq("newest")
    end
  end

  describe "GET /api/v1/posts/:id" do
    it "returns a post with attachments and comments" do
      post = create(:post, :with_attachments, user: user)
      create(:comment, post: post)

      get api_v1_post_path(post), headers: headers

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)

      expect(payload.dig("data", "id")).to eq(post.id)
      expect(payload.dig("data", "attachments").length).to eq(1)
      expect(payload.dig("data", "comments").length).to eq(1)
    end
  end

  describe "POST /api/v1/posts" do
    it "creates a post with attachments" do
      expect do
        post api_v1_posts_path,
             params: {
               post: {
                 date: "2026-03-31T12:00:00Z",
                 description: "Launch timeline",
                 post_attachments_attributes: [
                   { file_type: "photo", url: "https://cdn.example.com/photo.jpg" },
                   { file_type: "pdf", url: "https://cdn.example.com/doc.pdf" }
                 ]
               }
             },
             headers: headers
      end.to change(Post, :count).by(1).and change(PostAttachment, :count).by(2)

      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /api/v1/posts/:id" do
    it "updates the post attributes" do
      post_record = create(:post, user: user, description: "before")

      patch api_v1_post_path(post_record),
            params: { post: { description: "after" } },
            headers: headers

      expect(response).to have_http_status(:ok)
      expect(post_record.reload.description).to eq("after")
    end

    it "forbids updating another user's post" do
      post_record = create(:post)

      patch api_v1_post_path(post_record),
            params: { post: { description: "after" } },
            headers: headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/posts/:id" do
    it "deletes the post" do
      post_record = create(:post, user: user)

      expect do
        delete api_v1_post_path(post_record), headers: headers
      end.to change(Post, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "forbids deleting another user's post" do
      post_record = create(:post)

      expect do
        delete api_v1_post_path(post_record), headers: headers
      end.not_to change(Post, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/posts/:id/like" do
    it "likes a post once per user" do
      post_record = create(:post)

      expect do
        post like_api_v1_post_path(post_record), headers: headers
        post like_api_v1_post_path(post_record), headers: headers
      end.to change(Like, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(post_record.likes.count).to eq(1)
    end
  end

  describe "DELETE /api/v1/posts/:id/like" do
    it "removes a like from a post" do
      post_record = create(:post)
      create(:like, user: user, likable: post_record)

      expect do
        delete like_api_v1_post_path(post_record), headers: headers
      end.to change(Like, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "authentication" do
    it "rejects creating a post without user context" do
      post api_v1_posts_path,
           params: {
             post: {
               date: "2026-03-31T12:00:00Z",
               description: "Unauthorized post"
             }
           }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
