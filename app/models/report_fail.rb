# frozen_string_literal: true

# A class to action on failed labware events
class ReportFail
  # The following two modules include methods used by a number of rails helpers, such that we can
  # use them in eg. form_for
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :failed_labware_barcodes, :user_code, :failure_id, :failure_options, :selected_option, :disabled_options

  validates :failed_labware_barcodes, :user_code, :failure_id, presence: true
  validates :user,
            presence: {
              message:
                'could not be found with that swipecard or barcode. ' \
                'You may need to update your swipecard in Sequencescape.'
            }

  def initialize(user_code, failure_id, failed_labware_barcodes)
    @user_code = user_code.try(:strip)
    @failure_id = failure_id.try(:strip)
    @failed_labware_barcodes = (failed_labware_barcodes || []).map(&:strip)
  end

  def persisted?
    false
  end

  def user
    @user ||= User.find_with_barcode_or_swipecard_code(@user_code)
  end

  # save attempts to perform the actions, and returns true if it was successful
  # This maintains compatibility with rails
  def save
    return false unless valid?

    failed_labware.each do |labware|
      labware.events.create_labware_failed!(failure_id, user.login)
      BroadcastEvent::LabwareFailed.create!(seed: labware, user: user, properties: { failure_reason: failure_id })
    end

    valid?
  end

  def failed_labware
    @failed_labware ||= Labware.with_barcode(failed_labware_barcodes)
  end

  def missing_barcodes
    machine_barcodes = failed_labware.to_set(&:machine_barcode)
    human_barcodes = failed_labware.to_set(&:human_barcode)
    failed_labware_barcodes.delete_if do |barcode|
      human_barcodes.include?(barcode) || machine_barcodes.include?(barcode)
    end
  end
end
