
class UserQuery
  include ActiveModel::Model

  attr_accessor :user, :user_email, :url, :what_was_trying_to_do, :what_happened, :what_expected

  validates_presence_of :user_email, :user

  def initialize(attributes = {})
    super
    @user_email = update_user_email
  end

  def from
    user_email
  end

  def to
    configatron.admin_email
  end

  def date
    Time.now.to_formatted_s(:long_ordinal)
  end

  def update_user_email
    @user_email ||= (user.email if user.present?)
  end
end
