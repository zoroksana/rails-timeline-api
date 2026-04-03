require 'rails_helper'

RSpec.describe "Api::V1::Comments", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "X-User-Id" => user.id.to_s } }
  let(:post_record) { create(:post) }

  describe "GET /api/v1/posts/:post_id/comments" do
    it "returns comments for a post" do
      older_comment = create(:comment, post: post_record, body: "First")
      newer_comment = create(:comment, post: post_record, body: "Second")

      get api_v1_post_comments_path(post_record), headers: headers

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)

      expect(payload.dig("data", 0, "id")).to eq(older_comment.id)
      expect(payload.dig("data", 1, "id")).to eq(newer_comment.id)
    end
  end

  describe "POST /api/v1/posts/:post_id/comments" do
    it "creates a comment on a post" do
      expect do
        post api_v1_post_comments_path(post_record),
             params: { comment: { body: "Nice update" } },
             headers: headers
      end.to change(Comment, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(post_record.comments.last.body).to eq("Nice update")
    end
  end

  describe "POST /api/v1/comments/:id/like" do
    it "likes a comment" do
      comment = create(:comment, post: post_record)

      expect do
        post like_api_v1_comment_path(comment), headers: headers
      end.to change(Like, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(comment.likes.count).to eq(1)
    end

    it "likes a comment only once per user" do
      comment = create(:comment, post: post_record)

      expect do
        post like_api_v1_comment_path(comment), headers: headers
        post like_api_v1_comment_path(comment), headers: headers
      end.to change(Like, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(comment.likes.count).to eq(1)
    end
  end

  describe "DELETE /api/v1/comments/:id/like" do
    it "unlikes a comment" do
      comment = create(:comment, post: post_record)
      create(:like, user: user, likable: comment)

      expect do
        delete like_api_v1_comment_path(comment), headers: headers
      end.to change(Like, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
