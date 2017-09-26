class ApplicationController < ActionController::API
  include Response
  include ExceptionHandler
  def current_user_id
    @current_user_id ||= session[:member_id]
  end

  def auth_member!
    unless current_user_id && Rails.application.config_for(:fiat)["member_whitelist"].include?(current_user_id.to_s)
      json_response({}, 401)
    end
  end

  def fake_session
    reset_session rescue nil
    session[:member_id] = params[:member_id] || 1
  end
end
