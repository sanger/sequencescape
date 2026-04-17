# frozen_string_literal: true

module UserLogin
  # For use in feature tests. Login as either a new user, or an provided user
  #
  # @param [User] user The user to log in as, or nil to create a new user
  # @return [TrueClass] true
  def login_user(user)
    visit login_path
    fill_in 'Username', with: user.login
    fill_in 'Password', with: 'password'
    click_button 'Login'
    # wait for the login to complete before returning, so ready for whatever is next
    find_by_id('message_notice', text: 'Logged in successfully')
    true
  end
end
