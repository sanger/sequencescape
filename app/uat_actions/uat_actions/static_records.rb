# frozen_string_literal: true

# Provides simple consistent records where multiple records are not needed.
module UatActions::StaticRecords
  def self.study
    Study.create_with
         .find_or_create_by(name: 'UAT Study')
  end

  def self.project
    Project.create_with
           .find_or_create_by(name: 'UAT Study')
  end

  def self.user
    User.create_with(
      email: configatron.admin_email,
      first_name: 'Test',
      last_name: 'User',
      swipecard_code: '__uat_test__'
    ).find_or_create_by(login: '__uat_test__')
  end
end
