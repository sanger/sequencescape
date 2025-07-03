# frozen_string_literal: true

# Will fetch plate information for a plate barcode
class UatActions::PlateInformation < UatActions
  self.title = 'Plate information'
  self.description = 'Get plate information for a barcode.'
  self.category = :setup_and_test

  form_field :plate_barcode, :text_field, label: 'Plate Barcode', help: 'Fetches basic information for a plate barcode.'

  validates :plate_barcode, presence: { message: 'needs a value' }
  validates :plate, presence: { message: 'could not be found' }

  def self.default
    new
  end

  def perform
    report[:plate_barcode] = plate_barcode
    return false if plate.blank?

    report[:wells_with_aliquots] = wells_with_aliquots

    report[:wells_with_active_requests_as_source] = wells_with_active_requests_as_source
    true
  end

  private

  def plate
    @plate ||= Plate.find_by_barcode(plate_barcode.strip)
  end

  def wells_with_aliquots
    plate
      .wells_in_column_order
      .each_with_object([]) do |well, wells_with_aliquots|
        wells_with_aliquots << well.map_description if well.aliquots.present?
      end
      .join(', ')
  end

  # For finding wells in a partial submission plate that are to go forward.
  # i.e. wells will have active requests as source only if they are to progress.
  def wells_with_active_requests_as_source
    active_request_states = %w[pending started]

    plate
      .wells_in_column_order
      .each_with_object([]) do |well, wells_with_active_requests_as_source|
        # requests must have an active state
        if well.requests_as_source.present? &&
            well.requests_as_source.any? { |request| active_request_states.include?(request.state) }
          wells_with_active_requests_as_source << well.map_description
        end
      end
      .join(', ')
  end
end
