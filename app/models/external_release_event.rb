# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.
require 'eventful_mailer'
class ExternalReleaseEvent < Event
  after_create :physically_send_email, if: :send_email

  attr_accessor :send_email

  def self.create_for_asset!(asset, sendmail = false)
    create!(
      eventful: asset,
      message: "Data to be released externally set #{asset.external_release}",
      created_by: '', family: 'update', of_interest_to: 'administrators',
      send_email: sendmail
    )
  end

  def set_qc_state
    # This method should be empty!
  end

  def physically_send_email
    study = Asset.find(eventful_id).studies.map do |study|
      EventfulMailer.confirm_external_release_event(study.mailing_list_of_managers.reject(&:blank?), eventful, message, content, 'No Milestone').deliver_now
    end
  end
end
