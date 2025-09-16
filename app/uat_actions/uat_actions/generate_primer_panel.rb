# frozen_string_literal: true

# Will construct a primer panel
class UatActions::GeneratePrimerPanel < UatActions
  self.title = 'Generate primer panel'

  # The description displays on the list of UAT actions to provide additional information
  self.description = 'Generates a primer panel with the specified details.'
  self.category = :auxiliary_data

  # Form fields
  form_field :name,
             :text_field,
             label: 'Primer Panel Name',
             help: 'It will not create a primer panel with a name that already exists.'
  form_field :snp_count, :number_field, label: 'SNP count', help: 'The number of SNPs', options: { minimum: 1 }
  form_field :pcr_1_name, :text_field, label: 'PCR Program 1 Name', help: 'The name of the PCR 1 program.'
  form_field :pcr_1_duration,
             :number_field,
             label: 'PCR Program 1 Duration (minutes)',
             help: 'The duration of PCR Program 1 in minutes',
             options: {
               minimum: 1
             }
  form_field :pcr_2_name, :text_field, label: 'PCR Program 2 Name', help: 'The name of the PCR 2 program.'
  form_field :pcr_2_duration,
             :number_field,
             label: 'PCR Program 2 Duration (minutes)',
             help: 'The duration of PCR Program 2 in minutes',
             options: {
               minimum: 1
             }

  validates :name, presence: { message: 'needs a name' }
  validates :snp_count, numericality: { greater_than: 0, only_integer: true, allow_blank: false }
  validates :pcr_1_name, presence: { message: 'needs a pcr 1 program name' }
  validates :pcr_2_name, presence: { message: 'needs a pcr 2 program name' }
  validates :pcr_1_duration, numericality: { greater_than: 0, only_integer: true, allow_blank: false }
  validates :pcr_2_duration, numericality: { greater_than: 0, only_integer: true, allow_blank: false }

  #
  # Returns a default copy of the UatAction which will be used to fill in the form
  #
  # @return [UatActions::GeneratePrimerPanel] A default object for rendering a form
  def self.default
    new(snp_count: 48, pcr_1_name: 'Program 1', pcr_2_name: 'Program 2', pcr_1_duration: 60, pcr_2_duration: 60)
  end

  #
  # [perform description]
  #
  # @return [Boolean] Returns true if the action was successful, false otherwise
  def perform
    # Called by the controller once the form is filled in. Add your actual actions here.
    # All the form fields are accessible as simple attributes.
    # Return true if everything works
    report[:name] = name
    return true if existing_primer_panel

    primer_panel = PrimerPanel.create!(primer_panel_params)
    primer_panel.save
  end

  private

  # Any helper methods

  def existing_primer_panel
    return @existing_primer_panel if defined?(@existing_primer_panel)

    @existing_primer_panel = PrimerPanel.find_by(name:)
  end

  def primer_panel_params
    {
      name: name,
      snp_count: snp_count,
      programs: {
        'pcr 1' => {
          'name' => pcr_1_name,
          'duration' => pcr_1_duration
        },
        'pcr 2' => {
          'name' => pcr_2_name,
          'duration' => pcr_2_duration
        }
      }
    }
  end
end
