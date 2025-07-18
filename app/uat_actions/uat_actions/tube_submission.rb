# frozen_string_literal: true

# This UAT Action will generates a basic submission for tubes. Initially, it
# has been designed for generating scRNA Core Donor Pooling and cDNA Prep
# submissions on LRC Bank Seq/Spare tubes.
# rubocop:disable Metrics/ClassLength
class UatActions::TubeSubmission < UatActions
  self.title = 'Tube submission'
  self.description = 'Generates a basic submission for tubes.'
  self.category = :setup_and_test

  ERROR_SUBMISSION_TEMPLATE_DOES_NOT_EXIST = "Submission template '%s' does not exist."
  ERROR_TUBES_DO_NOT_EXIST = 'Tubes with barcodes do not exist: %s'
  ERROR_LIBRARY_TYPE_DOES_NOT_EXIST = "Library type '%s' does not exist."
  SCRNA_CORE_CDNA_PREP_GEM_X_5P = 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p'

  form_field :submission_template_name,
             :select,
             label: 'Submission Template',
             help: 'Select the submission template to use.',
             select_options: -> { compatible_submission_templates }

  form_field :tube_barcodes,
             :text_area,
             label: 'Tube barcodes',
             help: 'Add the tubes which will form part of your submission.'

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

  # The number_of_pools and cells_per_chip_well options are applied to a single
  # study-project and set in request metadata. For multiple study and projects,
  # a bulk submission is required.

  form_field :number_of_pools,
             :number_field,
             label: 'Number of pools',
             help:
               'Optional field to set the number_of_pools field on the ' \
               'submission request. Leave blank if not required.',
             options: {
               minimum: 0
             }

  form_field :cells_per_chip_well,
             :number_field,
             label: 'Cells per Chip Well',
             help:
               'Optional field to set the cells_per_chip_well field on the ' \
               'submission request. Leave blank if not required.',
             options: {
               minimum: 0
             }

  validates :submission_template, presence: { message: 'could not be found' }
  validates :tube_barcodes, presence: true

  validate :validate_submission_template_exists
  validate :validate_tubes_exist
  validate :validate_library_type_exists

  # Returns a default copy of the UatAction which will be used to fill in the form
  #
  # @return [UatActions::TestSubmission] A default object for rendering a form
  def self.default
    new
  end

  # Returns the submission templates which are compatible with the UAT action.
  # These are submission templates which have a tube as an input asset type.
  #
  # @return [Array<String>] The names of the compatible submission templates
  def self.compatible_submission_templates
    SubmissionTemplate
      .visible
      .each_with_object([]) do |submission_template, compatible|
        next unless submission_template.input_asset_type.constantize <= Tube

        compatible << submission_template.name
      end
  end

  # Generates tube submission for the given template.
  #
  # @return [Boolean] true if the submission was successfully created
  def perform
    order =
      submission_template.create_with_submission!(
        study: study,
        project: project,
        user: user,
        assets: assets,
        request_options: order_request_options
      )
    fill_report(order)
    order.submission.built!
    true
  end

  # Validates that the submission template exists for the specified submission
  # template name.
  #
  # @return [void]
  def validate_submission_template_exists
    return if submission_template_name.blank? # already validated by presence
    return if SubmissionTemplate.exists?(name: submission_template_name)

    message = format(ERROR_SUBMISSION_TEMPLATE_DOES_NOT_EXIST, submission_template_name)
    errors.add(:submission_template_name, message)
  end

  # Validates that the tubes exist for the specified barcodes.
  #
  # @return [void]
  def validate_tubes_exist
    return if tube_barcodes.blank? # already validated by presence

    barcodes =
      tube_barcodes
        .gsub(/(\\[trfvn])+/, ' ')
        .strip
        .split
        .select do |barcode|
          Tube.find_by_barcode(barcode).blank? # not found
        end
    return if barcodes.empty?

    # return if all tubes exist
    return if barcodes.blank?

    # add error message listing tubes that do not exist
    message = format(ERROR_TUBES_DO_NOT_EXIST, barcodes.join(', '))
    errors.add(:tube_barcodes, message)
  end

  # Validates that the library type exists for the specified library type name.
  #
  # return [void]
  def validate_library_type_exists
    return if library_type_name.blank? # optional
    return if LibraryType.exists?(name: library_type_name)

    message = format(ERROR_LIBRARY_TYPE_DOES_NOT_EXIST, library_type_name)
    errors.add(:library_type_name, message)
  end

  # Fills the report with the information from the submission
  #
  # @return [Void]
  # rubocop:disable Metrics/AbcSize
  def fill_report(order)
    report['tube_barcodes'] = assets.map(&:human_barcode)
    report['submission_id'] = order.submission.id
    report['library_type'] = order.request_options[:library_type] if order.request_options[:library_type].present?
    report['number_of_pools'] = order.request_options[:number_of_pools] if order.request_options[
      :number_of_pools
    ].present?
    report['cells_per_chip_well'] = order.request_options[:cells_per_chip_well] if order.request_options[
      :cells_per_chip_well
    ].present?
    report['allowance_band'] = order.request_options[:allowance_band] if order.request_options[:allowance_band].present?
  end

  # rubocop:enable Metrics/AbcSize

  # Returns the submisssion template to use for the submission
  #
  # @return [SubmissionTemplate] The submission template to use
  def submission_template
    @submission_template = SubmissionTemplate.find_by(name: submission_template_name)
  end

  # Returns the tubes to use for the submission
  #
  # @return [Array<Tube>] The tubes to use for the submission
  def assets
    @assets ||= select_assets
  end

  # Returns the tubes from the specified barcodes in the form field
  #
  # @return [Array<Tube>] The tubes to use for the submission
  def select_assets
    tube_barcodes.gsub(/(\\[trfvn])+/, ' ').split.map { |barcode| Tube.find_by_barcode(barcode) }
  end

  # Returns the request options to use for the submission
  #
  # @return [Hash] The request options to use for the submission
  def order_request_options
    default_request_options.merge(custom_request_options).merge(calculated_request_options_by_template_name)
  end

  # Returns the default request options to use for the submission
  #
  # @return [Hash] The default request options to use for the submission
  def default_request_options
    submission_template
      .input_field_infos
      .each_with_object({}) do |ifi, options|
        options[ifi.key] = (
          if ifi.default_value.nil?
            ifi.selection&.first.presence || ifi.max.presence || ifi.min
          else
            ifi.default_value
          end
        )
      end
  end

  # Returns the custom request options to use for the submission
  #
  # @return [Hash] The custom request options from the form
  def custom_request_options
    options = {}
    options[:library_type] = library_type_name if library_type_name.present?
    options[:number_of_pools] = number_of_pools.presence
    options[:cells_per_chip_well] = cells_per_chip_well.presence
    options
  end

  # Returns the allowance_band to prevent integration suite breakage
  # for the scRNA Core testing suite.
  #
  # Allowance bands are only supported for bulk submissions using the
  # Limber-HTP scRNA Core cDNA Prep GEM-X 5p template.
  # In bulk submissions, allowance_band is determined by the
  # `calculate_allowance_bands` method.
  #
  # The allowance_band is not included in the form, as it is a calculated value (does not require user input).
  #
  # @todo: Implement allowance_band support for standard tube submissions (Y25-153)
  # @todo: Remove this method once allowance_band is properly handled for tube submissions.
  #
  # @return [Hash] Request options including allowance_band if applicable.
  def calculated_request_options_by_template_name
    if submission_template_name == SCRNA_CORE_CDNA_PREP_GEM_X_5P
      { 'allowance_band' => '2 pool attempts, 2 counts' }
    else
      {}
    end
  end

  # Returns the study to use for UAT
  #
  # @return [Study] The study to use for UAT
  delegate :study, to: :'UatActions::StaticRecords'

  # Returns the project to use for UAT
  #
  # @return [Project] The project to use for UAT
  delegate :project, to: :'UatActions::StaticRecords'

  #
  # Returns the uat user
  #
  # @return [User] The UAT user can be used in any places where a user is expected.
  delegate :user, to: :'UatActions::StaticRecords'
end
# rubocop:enable Metrics/ClassLength
