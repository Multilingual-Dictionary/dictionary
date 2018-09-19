module SessionsHelper


  # Logs in the given user.
  def log_in(user)
    session[:user_id] = user.id
  end
  # Logs out
  def log_out
    session.delete(:user_id)
    @current_user = nil
  end

  # Returns the current logged-in user (if any).
  def current_user
    if session[:user_id]
      @current_user ||= User.find_by(id: session[:user_id])
    end
  end

  def current_user_name
      current_user
      if @current_user != nil
         return @current_user.name 
      end
      return ""
  end


end
