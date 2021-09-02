# frozen_string_literal: true

# A request information type associates a pipeline with request information,
# either via {Request::Metadata} or a {LabEvent}
class RequestInformationType < ApplicationRecord
  has_many :pipeline_request_information_types
  has_many :pipelines, through: :pipeline_request_information_types

  scope :shown_in_inbox, -> { where(hide_in_inbox: false) }

  attribute :data_type, default: 'String'

  FORMATTERS = { 'String' => ->(v) { v.to_s }, 'Date' => ->(v) { v.to_date&.strftime('%d %B %Y') } }.freeze

  # Data type can be used to specify a formatter for the data. At time of porting this behaviour from Request, all
  # entries in the production database have a value of NULL. I've decided to leave the functionality in place however,
  # as it feels like it may be of use.
  validates :data_type, inclusion: { in: FORMATTERS.keys }

  def data_type
    super || 'String'
  end

  def value_for(request, batch)
    format(metadata_for_information_type(request) || event_value_for(request, batch))
  end

  private

  def metadata_for_information_type(request)
    request.request_metadata.try(key)
  end

  def event_value_for(request, batch)
    request.detect_descriptor(name, descriptor_batch: batch)
  end

  def format(value)
    FORMATTERS[data_type].call(value)
  end
end
