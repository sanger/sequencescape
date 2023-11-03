# frozen_string_literal: true
module UsersHelper
  def logged_in_user?(user)
    yield if user == current_user
  end
end
