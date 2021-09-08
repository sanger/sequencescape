# frozen_string_literal: true
class RequestInformation < ApplicationRecord
  belongs_to :request_information_type
  belongs_to :request

  scope :information_type, ->(*args) { where(request_information_type_id: args[0]) }
end
