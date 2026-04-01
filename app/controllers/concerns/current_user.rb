module CurrentUser
  extend ActiveSupport::Concern

  included do
    before_action :require_current_user
  end

  private

  def current_user
    user_id = request.get_header("HTTP_X_USER_ID") ||
              request.env["HTTP_X_USER_ID"] ||
              request.headers["X-User-Id"] ||
              params[:user_id]
    @current_user ||= User.find_by(id: user_id)
  end

  def require_current_user
    return if current_user.present?

    render json: { error: "X-User-Id header is required and must reference an existing user" }, status: :unauthorized
  end
end
