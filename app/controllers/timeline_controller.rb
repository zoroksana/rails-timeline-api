class TimelineController < ActionController::Base
  include Pagy::Method

  helper_method :available_users, :selected_user, :liked_by_selected_user?, :like_frame_id, :selected_user_owns?, :selected_user_liked?, :current_sort_option, :pagination_window

  def landing
    @user = User.new
    @banner = params[:banner]
    users = User.order(:name)
    @users_pagy, @users = pagy(:offset, users, limit: 8, page_key: :users_page)
  end

  def index
    @post = Post.new
    @post.user_id = params[:user_id] if params[:user_id].present?
    @banner = params[:banner]
    posts = ordered_posts_scope
    @pagy, @posts = pagy(:offset, posts, limit: 8)
  end

  def show
    @post = Post.includes(:user, :post_attachments, comments: [ :user, :likes ]).find(params[:id])
    @comment = Comment.new
    @banner = params[:banner]
  end

  def create
    user = current_selected_user!
    post = user.posts.new(
      date: Time.current,
      description: timeline_post_params[:description]
    )

    attachment_file = timeline_post_params[:attachment_file]

    post.attachment_file = attachment_file

    if attachment_file.present?
      stored_attachment = store_uploaded_attachment(attachment_file)
      post.post_attachments.build(url: stored_attachment[:url], file_type: stored_attachment[:file_type])
    end

    if post.save
      redirect_to timeline_post_path(post, user_id: user.id, banner: "Post created.")
    else
      @post = post
      @post.user_id = user.id
      @banner = post.errors.full_messages.to_sentence
      posts = ordered_posts_scope
      @pagy, @posts = pagy(:offset, posts, limit: 8)
      render :index, status: :unprocessable_entity
    end
  end

  def create_comment
    post = Post.find(params[:id])
    user = current_selected_user!
    comment = post.comments.new(body: comment_params[:body], user: user)

    if comment.save
      redirect_to timeline_post_path(post, user_id: user.id, banner: "Comment added.")
    else
      @post = Post.includes(:user, :post_attachments, comments: [ :user, :likes ]).find(params[:id])
      @comment = comment
      @banner = comment.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  def update
    @post = Post.includes(:user, :post_attachments, comments: [ :user, :likes ]).find(params[:id])
    user = current_selected_user!
    return redirect_to timeline_post_path(@post, user_id: user.id, banner: "Only the post author can edit this post.") unless selected_user_owns?(@post)

    @post.description = timeline_post_params[:description]
    attachment_file = timeline_post_params[:attachment_file]

    if attachment_file.present?
      stored_attachment = store_uploaded_attachment(attachment_file)
      @post.post_attachments.build(url: stored_attachment[:url], file_type: stored_attachment[:file_type])
    end

    if @post.save
      redirect_to timeline_post_path(@post, user_id: user.id, banner: "Post updated.")
    else
      @comment = Comment.new
      @banner = @post.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    post = Post.find(params[:id])
    user = current_selected_user!
    return redirect_to timeline_post_path(post, user_id: user.id, banner: "Only the post author can delete this post.") unless selected_user_owns?(post)

    post.destroy!
    redirect_to timeline_path(user_id: user.id, banner: "Post deleted.")
  end

  def toggle_like
    post = Post.find(params[:id])
    user = User.find(params[:user_id])
    like = post.likes.find_by(user: user)

    if like
      like.destroy!
      return render_like_frame(post) if turbo_frame_request?

      redirect_to timeline_post_path(post, user_id: user.id, banner: "Post unliked.")
    else
      post.likes.create!(user: user)
      return render_like_frame(post) if turbo_frame_request?

      redirect_to timeline_post_path(post, user_id: user.id, banner: "Post liked.")
    end
  end

  def toggle_comment_like
    comment = Comment.includes(:post).find(params[:id])
    user = User.find(params[:user_id])
    like = comment.likes.find_by(user: user)

    if like
      like.destroy!
      redirect_to timeline_post_path(comment.post, user_id: user.id, banner: "Comment unliked.", anchor: "comment-#{comment.id}")
    else
      comment.likes.create!(user: user)
      redirect_to timeline_post_path(comment.post, user_id: user.id, banner: "Comment liked.", anchor: "comment-#{comment.id}")
    end
  end

  def create_user
    user = User.new(user_params)

    if user.save
      redirect_to timeline_path(user_id: user.id, banner: "User created.")
    else
      users = User.order(:name)
      @users_pagy, @users = pagy(:offset, users, limit: 8, page_key: :users_page)
      @user = user
      @banner = user.errors.full_messages.to_sentence
      render :landing, status: :unprocessable_entity
    end
  end

  def select_user
    user = User.find(params[:user_id])
    target = params[:redirect_to].presence || timeline_path

    redirect_to append_query_param(target, "user_id", user.id)
  end

  private

  def available_users
    @available_users ||= User.order(:name)
  end

  def selected_user
    return @selected_user if defined?(@selected_user)

    @selected_user = User.find_by(id: params[:user_id]) || available_users.first
  end

  def liked_by_selected_user?(post)
    return false unless selected_user

    post.likes.any? { |like| like.user_id == selected_user.id }
  end

  def selected_user_liked?(likable)
    return false unless selected_user

    likable.likes.any? { |like| like.user_id == selected_user.id }
  end

  def current_sort_option
    %w[newest oldest].include?(params[:sort]) ? params[:sort] : "newest"
  end

  def selected_user_owns?(post)
    selected_user && post.user_id == selected_user.id
  end

  def ordered_posts_scope
    scope = Post.includes(:user, :post_attachments, :comments, :likes)

    current_sort_option == "oldest" ? scope.timeline_order("date", "asc") : scope.timeline_order("date", "desc")
  end

  def pagination_window(pagy, radius: 2)
    start_page = [ pagy.page - radius, 1 ].max
    end_page = [ pagy.page + radius, pagy.pages ].min
    (start_page..end_page).to_a
  end

  def like_frame_id(post)
    "post_#{post.id}_like"
  end

  def timeline_post_params
    params.require(:post).permit(:description, :attachment_file)
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end

  def store_uploaded_attachment(file)
    extension = File.extname(file.original_filename.to_s).downcase
    filename = "#{SecureRandom.hex(10)}#{extension}"
    directory = Rails.root.join("public", "uploads")
    FileUtils.mkdir_p(directory)

    path = directory.join(filename)
    File.binwrite(path, file.read)

    {
      url: "/uploads/#{filename}",
      file_type: detect_attachment_type(file.content_type, extension)
    }
  end

  def detect_attachment_type(content_type, extension)
    return "photo" if content_type.to_s.start_with?("image/")
    return "video" if content_type.to_s.start_with?("video/")
    return "pdf" if content_type.to_s == "application/pdf" || extension == ".pdf"

    "photo"
  end

  def current_selected_user!
    selected_user || raise(ActiveRecord::RecordNotFound, "Please select a user first")
  end

  def turbo_frame_request?
    request.headers["Turbo-Frame"].present?
  end

  def render_like_frame(post)
    render partial: "timeline/post_like", locals: { post: post }
  end

  def append_query_param(url, key, value)
    uri = URI.parse(url)
    params = Rack::Utils.parse_nested_query(uri.query)
    params[key] = value
    uri.query = params.to_query.presence
    uri.to_s
  end
end
