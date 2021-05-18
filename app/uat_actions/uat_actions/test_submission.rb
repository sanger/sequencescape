# frozen_string_literal: true

# Will construct submissions
# Currently VERY basic
class UatActions::TestSubmission < UatActions # rubocop:todo Metrics/ClassLength
  self.title = 'Test submission'

  # The description displays on the list of UAT actions to provide additional information
  self.description =
    'Generates a basic submission for supported pipelines. ' \
      'This may produce odd results for some pipelines.'

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
  validates :number_of_wells_to_submit, numericality: { greater_than: 0, only_integer: true, allow_blank: true }

  #
  # Returns a default copy of the UatAction which will be used to fill in the form
  #
  # @return [UatActions::TestSubmission] A default object for rendering a form
  def self.default
    new
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
  # rubocop:todo Metrics/MethodLength
  def perform # rubocop:todo Metrics/AbcSize
    order =
      submission_template.create_with_submission!(
        study: study,
        project: project,
        user: user,
        assets: assets,
        request_options: order_request_options
      )
    report['plate_barcode_0'] = labware.human_barcode
    report['submission_id'] = order.submission.id
    report['library_type'] = order.request_options[:library_type] if order.request_options[:library_type].present?
    report['primer_panel'] = order.request_options[:primer_panel_name] if order.request_options[:primer_panel_name]
      .present?
    report['number_of_wells_with_samples'] = labware.wells.with_aliquots.size
    report['number_of_wells_to_submit'] = assets.size
    order.submission.built!
    true
  end

  # rubocop:enable Metrics/MethodLength

  private

  def submission_template
    @submission_template = SubmissionTemplate.find_by(name: submission_template_name)
  end

  def assets
    @assets ||= select_assets
  end

  # take a sample of the wells to go into the submission
  # rubocop:todo Metrics/MethodLength
  def select_assets # rubocop:todo Metrics/AbcSize
    num_subm_wells = number_of_wells_to_submit.to_i
    if num_subm_wells.zero?
      # default option, take all wells with aliquots
      labware.wells.with_aliquots
    else
      # take the number entered in the form
      reqd_num_samples = num_subm_wells

      # check the number is less than the total wells with aliquots
      # N.B. sort the array after random sampling to get back into original well order
      num_wells_with_aliquots = labware.wells.with_aliquots.size
      if reqd_num_samples > num_wells_with_aliquots
        labware.wells.with_aliquots
      else
        labware.wells.with_aliquots.sample(reqd_num_samples).sort_by(&:map_id)
      end
    end
  end

  # rubocop:enable Metrics/MethodLength

  def labware
    @labware ||= plate_barcode.blank? ? generate_plate : Plate.find_by_barcode(plate_barcode.strip)
  end

  def generate_plate # rubocop:todo Metrics/MethodLength
    generator = UatActions::GeneratePlates.default
    generator.plate_purpose_name = plate_purpose_name.presence || default_purpose_name

    num_sample_wells = number_of_wells_with_samples.to_i
    generator.well_count =
      if num_sample_wells.zero?
        # default option, create a full plate
        96
      else
        # take the number entered in the form
        num_sample_wells
      end
    generator.well_layout = 'Random'
    generator.perform
    Plate.find_by_barcode(generator.report['plate_0'])
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
