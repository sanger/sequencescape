
class RequestInformationType < ApplicationRecord
  has_many :pipeline_request_information_types
  has_many :pipelines, through: :pipeline_request_information_types

  scope :shown_in_inbox, ->() { where(hide_in_inbox: false) }
end
