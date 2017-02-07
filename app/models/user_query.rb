
class UserQuery

  include ActiveModel::Model

  attr_accessor :user, :user_name, :url, :what_was_trying_to_do, :what_happened, :what_expected

  validates_presence_of :user_name, :user

  def from
    user.email
  end

  def to
    configatron.admin_email
  end

  def date
    Time.now.to_formatted_s(:long_ordinal)
  end

end