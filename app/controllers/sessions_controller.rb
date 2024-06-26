class SessionsController < ApplicationController
  def new
    # Allow the login page to display in the bookmarklet iframe
    response.headers.delete "X-Frame-Options"
  end

  def create
    user = User.find_by("LOWER(email) = ?", params[:session][:email].downcase)
    if user.nil?
      redirect_to unknown_user_path and return false
    end

    now = Time.zone.now
    Rails.logger.info "#{now} login email requested for #{params[:session][:email].downcase}"
    UserMailer.login_email(user: user).deliver_later
    # Allow the login page to display in the bookmarklet iframe
    response.headers.delete "X-Frame-Options"
  end

  def token
    user = LoginToken.decode(token: params[:token])
    if user.present?
      if user[:expired]
        redirect_to expired_token_path(user[:user].id)
      else
        now = Time.zone.now
        Rails.logger.info "#{now} user with email #{user.email} and ID #{user.id} has successfully authenticated."
        cookies.signed[:user_id] = { value: user.id, expires: 7.days.from_now, httponly: true, same_site: :none, secure: true }
        redirect_to root_path
      end
    else
      redirect_to unknown_user_path
    end
  end

  def unknown_user
  end

  def expired_token
    @user = User.find(params[:user_id].to_i)
  end

  def destroy
    cookies.delete(:user_id)
    redirect_to root_path
  end
end
