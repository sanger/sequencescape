# frozen_string_literal: true

# Will construct plates with well_count wells filled with samples
class UatActions::GeneratePlates < UatActions
  self.title = 'Generate Plate'
  self.description = 'Generate plates '

  form_field :plate_purpose, :select, label: 'Plate Purpose', help: 'Select the plate purpose to create', select_options: -> { PlatePurpose.pluck(:name, :id) }
  form_field :plate_count, :number_field, label: 'Plate Count', help: 'The number of plates to generate', options: { minimum: 1 }
  form_field :well_count, :number_field, label: 'Well Count', help: 'The number of occupied wells on each plate', options: { minimum: 1 }

  def perform
    true
  end
end
