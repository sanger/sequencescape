# frozen_string_literal: true

# Handles failure of requests or their removal from the batch via
# BatchesController#fail_items
class Batch::RequestFailAndRemover
  include ActiveModel::Model

  attr_accessor :reason, :comment

  validates :reason, presence: { message: 'Please specify a failure reason for this batch' }

  # The used can either remove or fail a request, not both.
  validates :clashing_requests,
            absence: {
              message:
                lambda { |_, data|
                  # rubocop:todo Layout/LineLength
                  "Fail and remove were both selected for the following - #{data[:value].to_sentence} this is not supported."
                  # rubocop:enable Layout/LineLength
                }
            }

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      fail_requests if requested_fail.present?
      remove_requests if requested_remove.present?
    end

    true
  rescue ActiveRecord::RecordNotFound => e
    # Make the returned error a little more user friendly by stripping out the SQL
    errors.add(:base, e.message.gsub(/\[[^\[]*\] /, ''))
    false
  end

  def notice
    @notice ||= []
  end

  def failure=(failure_hash)
    @reason = failure_hash[:reason]
    @comment = failure_hash[:comment]
    @fail_but_charge = failure_hash[:fail_but_charge]
  end

  # ID is the batch id passed in from the controller
  def id=(batch_id)
    @batch = Batch.find(batch_id)
  end

  # This input comes in via the controller. It represents a series of checkboxes
  # which each have the value 'on' when checked. We filter out 'control' which is used
  # in place of the request id for some older batches.
  # We convert it to an array of the request_ids we care about
  def requested_fail=(selected_fields)
    @requested_fail = selected_fields.except('control').select { |_k, v| v == 'on' }.keys
  end

  # This input comes in via the controller. It represents a series of checkboxes
  # which each have the value 'on' when checked. We filter out 'control' which is used
  # in place of the request id for some older batches.
  # We convert it to an array of the request_ids we care about
  def requested_remove=(selected_fields)
    @requested_remove = selected_fields.except('control').select { |_k, v| v == 'on' }.keys
  end

  private

  def requested_fail
    @requested_fail || []
  end

  def requested_remove
    @requested_remove || []
  end

  def fail_requests
    @batch.fail_requests(requested_fail, reason, comment, fail_but_charge)
    notice << "#{requested_fail.length} requests failed#{charge_message}: #{requested_fail.to_sentence}."
  end

  def remove_requests
    @batch.remove_request_ids(requested_remove, reason, comment)
    notice << "#{requested_remove.length} requests removed: #{requested_remove.to_sentence}."
  end

  def charge_message
    fail_but_charge ? ', the customer will still be charged.' : ''
  end

  def clashing_requests
    requested_remove & requested_fail
  end

  def requests_selected?
    return if requested_remove.present? || requested_fail.present?

    errors.add(:base, 'Please select an item to fail or remove')
  end

  def fail_but_charge
    @fail_but_charge == '1'
  end
end
