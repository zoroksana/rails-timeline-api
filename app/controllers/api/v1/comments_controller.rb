class Api::V1::CommentsController < ApplicationController
  skip_before_action :require_current_user, only: [ :index ]
  def index
    render json: { data: post.comments.includes(:user).order(:created_at).map { |comment| serialize_comment(comment) } }
  end

  def create
    comment = post.comments.create!(comment_params.merge(user: current_user))
    render json: { data: serialize_comment(comment.reload) }, status: :created
  end

  def like
    comment.likes.find_or_create_by!(user: current_user)
    render json: { data: serialize_comment(comment.reload) }, status: :created
  end

  def unlike
    comment.likes.find_by!(user: current_user).destroy!
    head :no_content
  end

  private

  def post
    @post ||= Post.find(params[:post_id])
  end

  def comment
    @comment ||= Comment.includes(:user).find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def serialize_comment(record)
    {
      id: record.id,
      body: record.body,
      author: {
        id: record.user.id,
        name: record.user.name,
        email: record.user.email
      },
      likes_count: record.likes.count,
      created_at: record.created_at.iso8601,
      updated_at: record.updated_at.iso8601
    }
  end
end
