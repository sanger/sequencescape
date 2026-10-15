# frozen_string_literal: true

# A request received by an API operations endpoint, such as the Sapio
# reception and work order endpoint, and its processing progress.
#
# The calling system's request ID (external_id) and the request body
# (payload) are stored exactly as received. The payload digest identifies
# the payload, so a repeated request can be told apart from a changed one.
#
# Each processing task has its own status, starting as pending.
class ApiOperation < ApplicationRecord
  include Uuid::Uuidable

  belongs_to :api_application, optional: false

  validates :external_id, :operation_type, :payload, presence: true
  validates :payload_digest, presence: true, length: { is: 64 }
  validates :reception_status, :work_order_status, presence: true
end
