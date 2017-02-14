module Accession
  # The contact will be the person who will be informed if accessioning errors
  # or if the status needs to be checked.
  # Is this ever used?
  class Contact
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def name
      @name ||= "#{user.first_name} #{user.last_name}"
    end

    def email
      @email ||= "#{user.login}@#{configatron.default_email_domain}"
    end

    def to_h
      {
        inform_on_error: email,
        inform_on_status: email,
        name: name
      }
    end
  end
end
