# frozen_string_literal: true
require 'eventful_mailer'
class ExternalReleaseEvent < Event
  after_create :physically_send_email, if: :send_email

  attr_accessor :send_email

  def self.create_for_asset!(asset, sendmail = false)
    create!(
      eventful: asset,
      message: "Data to be released externally set #{asset.external_release}",
      created_by: '',
      family: 'update',
      of_interest_to: 'administrators',
      send_email: sendmail
    )
  end

  def set_qc_state
    # This method should be empty!
  end

  def physically_send_email
    studies = eventful.studies
    users = studies.reduce([]) { |users, study| users.concat(study.mailing_list_of_managers.compact_blank) }
    return false if users.empty?

    EventfulMailer.confirm_external_release_event(users.uniq, eventful, message, content, 'No Milestone').deliver_now
  end
end
