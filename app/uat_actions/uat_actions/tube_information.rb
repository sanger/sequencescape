# frozen_string_literal: true

# Will fetch tube information for a tube barcode
class UatActions::TubeInformation < UatActions
  self.title = 'Tube information'
  self.description = 'Get tube information for a barcode.'
  self.category = :setup_and_test

  form_field :tube_barcode, :text_field, label: 'Tube Barcode', help: 'Fetches basic information for a tube barcode.'

  validates :tube_barcode, presence: { message: 'needs a value' }
  validates :tube, presence: { message: 'could not be found' }

  def self.default
    new
  end

  def perform
    report[:tube_barcode] = tube_barcode
    return false if tube.blank?

    report[:tube_purpose] = tube.purpose.name
    report[:tube_requests_as_source_types] = tube_requests_as_source_types
    true
  end

  private

  def tube
    @tube ||= Tube.find_by_barcode(tube_barcode.strip)
  end

  # For viewing requests as source types for a tube
  def tube_requests_as_source_types
    active_request_states = %w[pending started]
    active_requests_as_source = []
    if tube.requests_as_source.present?
      tube.requests_as_source.each do |request|
        active_requests_as_source << request if active_request_states.include?(request.state)
      end
    end
    active_requests_as_source.map { |request| request.request_type.name }
  end
end
