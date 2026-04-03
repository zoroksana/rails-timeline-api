class Api::V1::CommentsController < ApplicationController
  skip_before_action :require_current_user, only: [ :index ]

  def index
    render json: { data: post.comments.includes(:user, :likes).order(:created_at).map { |comment| serialize_comment(comment) } }
  end

  def create
    comment = post.comments.create!(comment_params.merge(user: current_user))
    render json: { data: serialize_comment(comment.reload) }, status: :created
  end

  def like
    ensure_like(comment)
    render json: { data: serialize_comment(comment.reload) }, status: :created
  end

  def unlike
    comment.likes.destroy_by(user: current_user)
    head :no_content
  end

  private

  def post
    @post ||= Post.find(params[:post_id])
  end

  def comment
    @comment ||= Comment.includes(:user, :likes).find(params[:id])
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
        name: record.user.name
      },
      likes_count: record.likes.size,
      created_at: record.created_at.iso8601,
      updated_at: record.updated_at.iso8601
    }
  end

  def ensure_like(likable)
    existing_like = likable.likes.find_by(user: current_user)
    return existing_like if existing_like

    like = likable.likes.new(user: current_user)
    like.save!(validate: false)
    like
  rescue ActiveRecord::RecordNotUnique
    likable.likes.find_by!(user: current_user)
  end
end
