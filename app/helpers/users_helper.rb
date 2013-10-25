module UsersHelper
  def logged_in_user?
    yield if @user == current_user
  end
end
