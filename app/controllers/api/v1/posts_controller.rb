class Api::V1::PostsController < ApplicationController
  skip_before_action :require_current_user, only: [ :index, :show ]
  before_action :authorize_post_owner!, only: [ :update, :destroy ]

  def index
    posts = Post.includes(:user, :post_attachments, :likes, :comments).timeline_order(params[:sort], params[:direction])
    pagy, records = pagy(:offset, posts, limit: per_page)

    render json: {
      data: records.map { |post| serialize_post(post) },
      meta: {
        page: pagy.page,
        per_page: pagy.limit,
        total_pages: pagy.pages,
        total_count: pagy.count
      }
    }
  end

  def show
    render json: { data: serialize_post(post, include_comments: true) }
  end

  def create
    new_post = current_user.posts.create!(post_params)
    render json: { data: serialize_post(new_post.reload, include_comments: true) }, status: :created
  end

  def update
    post.update!(post_params)
    render json: { data: serialize_post(post.reload, include_comments: true) }
  end

  def destroy
    post.destroy!
    head :no_content
  end

  def like
    ensure_like(post)
    render json: { data: serialize_post(post.reload) }, status: :created
  end

  def unlike
    post.likes.destroy_by(user: current_user)
    head :no_content
  end

  private

  def post
    @post ||= Post.includes(:user, :post_attachments, :likes, comments: [ :user, :likes ]).find(params[:id])
  end

  def per_page
    value = params.fetch(:per_page, 10).to_i
    value.positive? ? [ value, 50 ].min : 10
  end

  def post_params
    params.require(:post).permit(
      :date,
      :description,
      post_attachments_attributes: [ :id, :file_type, :url, :_destroy ]
    )
  end

  def serialize_post(record, include_comments: false)
    payload = {
      id: record.id,
      date: record.date.iso8601,
      description: record.description,
      author: serialize_user(record.user),
      attachments: record.post_attachments.map { |attachment| serialize_attachment(attachment) },
      likes_count: record.likes.size,
      comments_count: record.comments.size,
      created_at: record.created_at.iso8601,
      updated_at: record.updated_at.iso8601
    }

    if include_comments
      payload[:comments] = record.comments.order(:created_at).map { |comment| serialize_comment(comment) }
    end

    payload
  end

  def serialize_comment(record)
    {
      id: record.id,
      body: record.body,
      author: serialize_user(record.user),
      likes_count: record.likes.size,
      created_at: record.created_at.iso8601,
      updated_at: record.updated_at.iso8601
    }
  end

  def serialize_attachment(record)
    {
      id: record.id,
      file_type: record.file_type,
      url: record.url
    }
  end

  def serialize_user(record)
    {
      id: record.id,
      name: record.name
    }
  end

  def authorize_post_owner!
    return if post.user_id == current_user.id

    render json: { error: "Only the post author can modify this post" }, status: :forbidden
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
