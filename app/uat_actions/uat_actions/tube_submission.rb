# frozen_string_literal: true

# This UAT Action will generates a basic submission for tubes. Initially, it
# has been designed for generating scRNA Core Donor Pooling and cDNA Prep
# submissions on LRC Bank Seq/Spare tubes.
class UatActions::TubeSubmission < UatActions
  self.title = 'Tube submission'
  self.description = 'Generates a basic submission for tubes.'
  self.category = :setup_and_test

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

  validates :submission_template, presence: { message: 'could not be found' }

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

  # Fills the report with the information from the submission
  #
  # @return [Void]
  def fill_report(order)
    report['tube_barcodes'] = assets.map(&:human_barcode)
    report['submission_id'] = order.submission.id
    report['library_type'] = order.request_options[:library_type] if order.request_options[:library_type].present?
  end

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
    default_request_options.merge(custom_request_options)
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
    options
  end

  # Returns the study to use for UAT
  #
  # @return [Study] The study to use for UAT
  def study
    UatActions::StaticRecords.study
  end

  # Returns the project to use for UAT
  #
  # @return [Project] The project to use for UAT
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
