# frozen_string_literal: true

# Will construct submissions
# Currently VERY basic
class UatActions::TestSubmission < UatActions
  self.title = 'Test submission'
  # The description displays on the list of UAT actions to provide additional information
  self.description = 'Generates a basic submission for supported pipelines. '\
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
             help: 'Add the plate which will form part of your submission. '\
                   'Leave blank to automatically generate compatible labware. '\
                   'This page does not currently support cross-plate submissions.'
  form_field :plate_purpose_name,
             :select,
             label: 'Plate Purpose',
             help: 'Select the plate purpose to use when creating the plate. '\
                   'Leave blank to automatically use the most appropriate purpose. '\
                   'Not used if plate barcode is supplied.',
             select_options: -> { PlatePurpose.alphabetical.pluck(:name) },
             options: { include_blank: 'Using default purpose...' }

  validates :submission_template, presence: { message: 'could not be found' }

  validates :submission_template, presence: { message: 'could not be found' }

  #
  # Returns a default copy of the UatAction which will be used to fill in the form
  #
  # @return [UatActions::TestSubmission] A default object for rendering a form
  def self.default
    new
  end

  def self.compatible_submission_templates
    SubmissionTemplate.visible.each_with_object([]) do |submission_template, compatible|
      next unless submission_template.input_asset_type == 'Well'

      compatible << submission_template.name
    end
  end

  #
  # Generates a full plate submission for the given template
  #
  # @return [Boolean] Returns true if the action was successful, false otherwise
  def perform
    order = submission_template.create_with_submission!(
      study: study,
      project: project,
      user: user,
      assets: assets,
      request_options: default_request_options
    )
    report['plate_barcode_0'] = labware.human_barcode
    report['submission_id'] = order.submission.id
    order.submission.built!
    true
  end

  private

  def submission_template
    @submission_template = SubmissionTemplate.find_by(name: submission_template_name)
  end

  def assets
    @assets ||= labware.wells.with_aliquots
  end

  def labware
    @labware ||= if plate_barcode.blank?
                   generate_plate
                 else
                   Plate.find_by_barcode(plate_barcode.strip)
                 end
  end

  def generate_plate
    generator = UatActions::GeneratePlates.default
    generator.plate_purpose_name = plate_purpose_name.presence || default_purpose_name
    generator.well_count = 90
    generator.well_layout = 'Random'
    generator.perform
    Plate.find_by_barcode(generator.report['plate_0'])
  end

  def default_request_options
    submission_template.input_field_infos.each_with_object({}) do |ifi, options|
      options[ifi.key] = if ifi.default_value.nil?
                           ifi.selection&.first.presence || ifi.max.presence || ifi.min
                         else
                           ifi.default_value
                         end
    end
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
