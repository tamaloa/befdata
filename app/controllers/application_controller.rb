class ::ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user_session, :current_user
  #layout "application"

  access_control :deny_access_to_all do
    deny all
  end

  def access_denied
    if current_user
      flash[:error] = 'Access denied. You do not have the appropriate rights to perform this operation.'
      redirect_to :back
    else
      flash[:error] = 'Access denied. Try to log in first.'
      session[:return_to] = request.env['HTTP_REFERER']
      redirect_to login_path
    end
  end

  def dataset_is_free_for_members
    return true if @dataset.free_for_members unless @dataset.blank?
    false
  end

  def dataset_is_free_for_public
    return true if @dataset.free_for_public unless @dataset.blank?
    false
  end


protected

  def layout_from_config
    LayoutHelper::BEF_LAYOUT
  end


private

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def require_user
    unless current_user
      store_location
      flash[:error] = "You must be logged in to access this page"
      redirect_to :login
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:error] = "You must be logged out to access this page"
      redirect_to account_url
      return false
    end
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default (default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def current_cart
    cookies[:cart_id] ||= Cart.create!.id
    begin
      @current_cart ||= Cart.find(cookies[:cart_id])
    rescue
      cookies[:cart_id] = Cart.create!.id
      @current_cart ||= Cart.find(cookies[:cart_id])
    end

  end

end
