# frozen_string_literal: true

module Limber::Helper
  PIPELINE = 'Limber-Htp'
  PIPELINE_REGEX = /Illumina-[A-z]+ /
  PRODUCTLINE = 'Illumina-Htp'
  DEFAULT_REQUEST_CLASS = 'IlluminaHtp::Requests::StdLibraryRequest'
  DEFAULT_LIBRARY_TYPES = ['Standard']
  DEFAULT_PURPOSES = ['LB Cherrypick']

  class RequestTypeConstructor
    def initialize(prefix,
                   request_class: DEFAULT_REQUEST_CLASS,
                   library_types: DEFAULT_LIBRARY_TYPES,
                   default_purposes: DEFAULT_PURPOSES,
                   for_multiplexing: false,
                   product_line: PRODUCTLINE)
      @prefix = prefix
      @request_class = request_class
      @library_types = library_types
      @default_purposes = default_purposes
      @for_multiplexing = for_multiplexing
      @product_line = product_line
    end

    def key
      "limber_#{@prefix.downcase.tr(' ', '_')}"
    end

    # Builds the corresponding request type, unless it
    # already exists.
    def build!
      rt = RequestType.create_with(
        name: "Limber #{@prefix}",
        request_class_name: @request_class,
        asset_type: 'Well',
        order: 1,
        initial_state: 'pending',
        billable: true,
        product_line: ProductLine.find_or_create_by!(name: @product_line),
        request_purpose: :standard,
        for_multiplexing: @for_multiplexing
      ).find_or_create_by!(key: key) do |rt|
        rt.acceptable_plate_purposes = Purpose.where(name: @default_purpose)
      end

      @library_types.each { |name| rt.library_types.find_or_create_by!(name: name) }

      return true if rt.request_type_validators.where(request_option: 'library_type').exists?

      RequestType::Validator.create!(
        request_type: rt,
        request_option: 'library_type',
        valid_options: RequestType::Validator::LibraryTypeValidator.new(rt.id)
      )
    end
  end

  class TemplateConstructor
    include ActiveModel::Model
    attr_writer :name, :type, :role, :prefix, :cherrypicked, :sequencing_keys, :catalogue, :pipeline, :product_line
    attr_reader :catalogue, :prefix

    def self.find_for(name, sequencing = nil)
      tc = TemplateConstructor.new(name: name, sequencing: sequencing)
      [true, false].map do |cherrypick|
        tc.sequencing.map do |sequencing_request_type|
          SubmissionTemplate.find_by!(name: tc.name_for(cherrypick, sequencing_request_type))
        end
      end.flatten
    end

    validates :name, presence: { message: 'must be specified, or prefix should be provided' }
    validates :role, presence: { message: 'must be specified, or prefix should be provided' }
    validates :type, presence: { message: 'must be specified, or prefix should be provided' }
    validates :catalogue, presence: true

    # Construct submission templates for the Limber pipeline
    #
    # @param [String] prefix: nil The prefix for the given limber pipeline (eg. WGS)
    # @param [ProductCatalogue] catalogue: The product catalogue that matches the submission.
    #                           Note: Most limber stuff will use a simple SingleProduct catalogue with a product names after the prefix.
    # The following parameters are optional, and usually get calculated from the prefix.
    # @param [String] name: nil Optional: The library creation portion of the submission template name
    #                           defaults to the prefix.
    # @param [String] type: nil Optional: The library creation request key (eg. limber_wgs) for the templates.
    #                           Calculated from the prefix by default.
    # @param [String] role: nil Optional: A string matching the desired order role. Defaults to the prefix.
    # The following are optional and change the range of submission templates constructed.
    # @param [String] cherrypicked: true Boolean. Set to false to generate submission templates with in built cherrypicking.
    # @param [Array] sequencing_keys: Array of sequencing request type keys to build templates for. Defaults to all appropriate request types.

    def name
      @name || prefix
    end

    def role
      @role || prefix
    end

    def pipeline
      @pipeline || PIPELINE
    end

    def product_line
      @product_line || PRODUCTLINE
    end

    def type
      @type || "limber_#{prefix.downcase.tr(' ', '_')}"
    end

    def sequencing_request_types
      @sequencing_request_types ||= @sequencing_keys.map do |request|
        RequestType.find_by!(key: request)
      end
    end

    def name_for(cherrypick, sequencing_request_type)
      "#{pipeline} - #{cherrypick ? 'Cherrypicked - ' : ''}#{name} - #{sequencing_request_type.name.gsub(PIPELINE_REGEX, '')}"
    end

    def build!
      validate!
      each_submission_template do |config|
        SubmissionTemplate.create!(config)
      end
    end

    private

    def product_line_id
      @product_line_id ||= ProductLine.find_or_create_by(name: product_line).id
    end

    def library_request_type
      @library_request_type ||= RequestType.find_by!(key: type)
    end

    def cherrypick_request_type
      RequestType.find_by!(key: 'cherrypick_for_limber')
    end

    def multiplexing_request_type
      RequestType.find_by!(key: 'limber_multiplexing')
    end

    def request_type_ids(cherrypick, sequencing)
      ids = []
      ids << [cherrypick_request_type.id] if cherrypick
      ids << [library_request_type.id]
      ids << [multiplexing_request_type.id] unless library_request_type.for_multiplexing?
      ids << [sequencing.id]
    end

    def cherrypick_options
      @cherrypicked ? [true, false] : [false]
    end

    def each_submission_template
      cherrypick_options.each do |cherrypick|
        sequencing_request_types.each do |sequencing_request_type|
          next if SubmissionTemplate.where(name: name_for(cherrypick, sequencing_request_type)).exists?

          yield({
            name: name_for(cherrypick, sequencing_request_type),
            submission_class_name: 'LinearSubmission',
            submission_parameters: submission_parameters(cherrypick, sequencing_request_type),
            product_line_id: product_line_id,
            product_catalogue: catalogue
          })
        end
      end
    end

    def submission_parameters(cherrypick, sequencing)
      {
        request_type_ids_list: request_type_ids(cherrypick, sequencing),
        order_role_id: OrderRole.find_or_create_by(role: role).id
      }
    end
  end

  #
  # Class LibraryOnlyTemplateConstructor provides a template constructor
  # which JUST build the library portion of the submission template.
  # No multiplexing or sequencing requests are added.
  #
  class LibraryOnlyTemplateConstructor < TemplateConstructor
    def name_for(cherrypick, _sequencing_request_type)
      "#{pipeline} - #{cherrypick ? 'Cherrypicked - ' : ''}#{name}"
    end

    def sequencing_request_types
      [nil]
    end

    def request_type_ids(cherrypick, _sequencing)
      ids = []
      ids << [cherrypick_request_type.id] if cherrypick
      ids << [library_request_type.id]
    end
  end
end
