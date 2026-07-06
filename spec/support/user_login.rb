# frozen_string_literal: true

module UserLogin
  # For use in feature tests. Login as either a new user, or an provided user
  #
  # @param [User] user The user to log in as, or nil to create a new user
  def login_user(user)
    visit_and_wait_for_title(login_path, 'Login')
    fill_in 'Username', with: user.login
    fill_in 'Password', with: 'password'
    click_button 'Login'
    expect(page).to have_css('#message_notice', text: 'Logged in successfully')
    nil
  end
end
