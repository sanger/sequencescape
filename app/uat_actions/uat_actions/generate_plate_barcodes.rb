# frozen_string_literal: true

# Will generate new plate barcodes
class UatActions::GeneratePlateBarcodes < UatActions
  self.title = 'Generate plate barcodes'
  self.description = 'Generates the specified number of new plate barcodes.'
  self.category = :auxiliary_data

  form_field :number_of_barcodes_to_generate,
             :number_field,
             label: 'Number of barcodes to generate',
             help: 'The number of plate barcodes that should be generated',
             options: {
               min: 1,
               max: 96
             }

  validates :number_of_barcodes_to_generate,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than_or_equal_to: 96
            }

  #
  # Returns a default copy of the UatAction which will be used to fill in the form
  #
  # @return [UatActions::GeneratePlateBarcodes] A default object for rendering a form
  def self.default
    new(number_of_barcodes_to_generate: 1)
  end

  #
  # Generates the barcodes and adds them to the report
  #
  # @return [Boolean] Returns true if the action was successful, false otherwise
  def perform
    report['barcodes'] = Array.new(number_of_barcodes_to_generate.to_i) { PlateBarcode.create_barcode.barcode }
    true
  end
end
