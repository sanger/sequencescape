# frozen_string_literal: true

# Will construct submissions
# Currently VERY basic
class UatActions::TestSubmission < UatActions
  self.title = 'Test submission'

  # The description displays on the list of UAT actions to provide additional information
  self.description =
    'Generates a basic submission for supported pipelines. ' \
      'This may produce odd results for some pipelines.'
  self.category = :setup_and_test

  # Form fields
  form_field :submission_template_name,
             :select,
             label: 'Submission Template',
             help: 'Select the submission template to use.',
             select_options: -> { compatible_submission_templates }
  form_field :plate_barcode,
             :text_field,
             label: 'Plate barcode',
             help:
               'Add the plate which will form part of your submission. ' \
                 'Leave blank to automatically generate compatible labware. ' \
                 'This page does not currently support cross-plate submissions.'
  form_field :plate_purpose_name,
             :select,
             label: 'Plate Purpose',
             help:
               'Select the plate purpose to use when creating the plate. ' \
                 'Leave blank to automatically use the most appropriate purpose. ' \
                 'Not used if plate barcode is supplied.',
             select_options: -> { PlatePurpose.alphabetical.pluck(:name) },
             options: {
               include_blank: 'Using default purpose...'
             }
  form_field :library_type_name,
             :select,
             label: 'Library Type',
             help:
               'Select the library type to use when creating the requests. ' \
                 'Leave blank to automatically use the first library type found. ' \
                 'Useful where the same request type has multiple library types.',
             select_options: -> { LibraryType.alphabetical.pluck(:name) },
             options: {
               include_blank: 'Using default library type...'
             }
  form_field :primer_panel_name,
             :select,
             label: 'Primer Panel',
             help:
               'Select the primer panel to use when creating the requests. ' \
                 'Leave blank if not applicable for your submission template choice. ' \
                 'Currently only used in GBS and Heron pipelines.',
             select_options: -> { PrimerPanel.alphabetical.pluck(:name) },
             options: {
               include_blank: 'Primer panel selection...'
             }
  form_field :number_of_wells_with_samples,
             :number_field,
             label: 'Number of wells with samples',
             help:
               'Use this option to create a partial plate of samples. Enter ' \
                 'the number of wells with samples. ' \
                 'Leave blank to use all wells.',
             options: {
               minimum: 1
             }
  form_field :number_of_samples_in_each_well,
             :number_field,
             label: 'Number of samples per occupied well',
             help:
               'Use this option to create wells containing a pool of multiple samples. Enter ' \
                 'the number of samples per well. All occupied wells will have this number of samples.' \
                 'Useful for a pipeline where pools of starting samples is required.' \
                 'Leave blank for 1 sample per well. Max 10 samples per well.',
             options: {
               minimum: 1,
               maximum: 10
             }
  form_field :number_of_wells_to_submit,
             :number_field,
             label: 'Number of wells to submit',
             help:
               'Use this option to create a partial submission. Enter the ' \
                 'number of randomly sampled wells to be submitted. ' \
                 'Leave blank to use all wells.',
             options: {
               minimum: 1
             }

  validates :submission_template, presence: { message: 'could not be found' }
  validates :number_of_wells_with_samples, numericality: { greater_than: 0, only_integer: true, allow_blank: true }
  validates :number_of_samples_in_each_well, numericality: { greater_than: 0, only_integer: true, allow_blank: true }
  validates :number_of_wells_to_submit, numericality: { greater_than: 0, only_integer: true, allow_blank: true }

  #
  # Returns a default copy of the UatAction which will be used to fill in the form
  #
  # @return [UatActions::TestSubmission] A default object for rendering a form
  def self.default
    new(number_of_samples_in_each_well: 1)
  end

  def self.compatible_submission_templates
    SubmissionTemplate
      .visible
      .each_with_object([]) do |submission_template, compatible|
        next unless submission_template.input_asset_type == 'Well'

        compatible << submission_template.name
      end
  end

  #
  # Generates a plate submission for the given template.
  # A partial submission is possible if the number_of_wells_to_submit form field has been set.
  #
  # @return [Boolean] Returns true if the action was successful, false otherwise
  def perform # rubocop:todo Metrics/AbcSize
    order =
      submission_template.create_with_submission!(
        study:,
        project:,
        user:,
        assets:,
        request_options: order_request_options
      )
    report['plate_barcode_0'] = labware.human_barcode
    report['submission_id'] = order.submission.id
    report['library_type'] = order.request_options[:library_type] if order.request_options[:library_type].present?
    report['primer_panel'] = order.request_options[:primer_panel_name] if order.request_options[:primer_panel_name]
      .present?
    report['number_of_wells_with_samples'] = labware.wells.with_aliquots.size
    report['number_of_samples_in_each_well'] = labware.wells.with_aliquots.first.aliquots.size
    report['number_of_wells_to_submit'] = assets.size
    order.submission.built!
    true
  end

    private

  def submission_template
    @submission_template = SubmissionTemplate.find_by(name: submission_template_name)
  end

  def assets
    @assets ||= select_assets
  end

  # take a selection of the wells to go into the submission
  def select_assets
    num_wells_to_submit_from_plate = number_of_wells_to_submit.to_i

    # fetch wells with aliquots, and remove duplicates in cases where multiple aliquots per well
    wells_with_aliquots = labware.wells.with_aliquots.uniq

    # return all wells if a subset is not required or the requested number is greater than the total wells with aliquots
    if num_wells_to_submit_from_plate.zero? || num_wells_to_submit_from_plate > wells_with_aliquots.size
      wells_with_aliquots
    else
      # N.B. sort the array after random sampling to get back into original well order
      wells_with_aliquots.sample(num_wells_to_submit_from_plate).sort_by(&:map_id)
    end
  end

  def labware
    @labware ||= plate_barcode.blank? ? generate_plate : Plate.find_by_barcode(plate_barcode.strip)
  end

  # Ensures number of samples per occupied well is at least 1
  def num_samples_per_well
    @num_samples_per_well ||=
      if number_of_samples_in_each_well.present? && number_of_samples_in_each_well.to_i.positive?
        number_of_samples_in_each_well.to_i
      else
        1
      end
  end

  # Generates a new plate using a plate generator.
  # The generator is set up with the appropriate parameters, then used to perform the plate generation.
  # After the plate is generated, the barcode is retrieved.
  # @return [Plate] the newly generated Plate object
  def generate_plate
    generator = setup_generator
    generator.perform
    Plate.find_by_barcode(generator.report['plate_0'])
  end

  # Sets up a plate generator with the appropriate parameters.
  # The generator is created with default settings, then its attributes are set based on the current object's state.
  # The plate purpose name is set to the plate_purpose_name entered by the user, or to the default purpose name if
  # plate_purpose_name is not present.
  # The well count is determined by the `determine_well_count` method.
  # The well layout is set to 'Random'.
  # The number of samples in each well is set to num_samples_per_well.
  # @return [UatActions::GeneratePlates] the configured plate generator
  def setup_generator
    generator = UatActions::GeneratePlates.default
    generator.plate_purpose_name = plate_purpose_name.presence || default_purpose_name
    generator.well_count = determine_well_count
    generator.well_layout = 'Random'
    generator.number_of_samples_in_each_well = num_samples_per_well
    generator
  end

  def determine_well_count
    num_sample_wells = number_of_wells_with_samples.to_i
    num_sample_wells.zero? ? 96 : num_sample_wells
  end

  def order_request_options
    default_request_options.merge(custom_request_options)
  end

  def default_request_options
    submission_template
      .input_field_infos
      .each_with_object({}) do |ifi, options|
        options[ifi.key] =
          ifi.default_value.nil? ? ifi.selection&.first.presence || ifi.max.presence || ifi.min : ifi.default_value
      end
  end

  def custom_request_options
    options = {}
    options[:library_type] = library_type_name if library_type_name.present?
    options[:primer_panel_name] = primer_panel_name if primer_panel_name.present?
    options
  end

  def default_purpose_name
    submission_template.input_plate_purposes.first&.name || PlatePurpose.stock_plate_purpose.name
  end

  # Any helper methods

  def study
    UatActions::StaticRecords.study
  end

  def project
    UatActions::StaticRecords.project
  end

  #
  # Returns the uat user
  #
  # @return [User] The UAT user can be used in any places where a user is expected.
  def user
    UatActions::StaticRecords.user
  end
end
