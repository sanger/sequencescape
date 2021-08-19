# frozen_string_literal: true

module Limber::Helper
  PIPELINE = 'Limber-Htp'
  PIPELINE_REGEX = /Illumina-[A-z]+ /.freeze
  PRODUCTLINE = 'Illumina-Htp'
  DEFAULT_REQUEST_CLASS = 'IlluminaHtp::Requests::StdLibraryRequest'
  DEFAULT_LIBRARY_TYPES = ['Standard'].freeze
  DEFAULT_PURPOSES = ['LB Cherrypick'].freeze

  # Build a Limber library creation request type
  class RequestTypeConstructor
    # rubocop:todo Metrics/ParameterLists
    def initialize(
      prefix,
      request_class: DEFAULT_REQUEST_CLASS,
      library_types: DEFAULT_LIBRARY_TYPES,
      default_purposes: DEFAULT_PURPOSES,
      for_multiplexing: false,
      product_line: PRODUCTLINE
    )
      @prefix = prefix
      @request_class = request_class
      @library_types = library_types
      @default_purposes = default_purposes
      @for_multiplexing = for_multiplexing
      @product_line = product_line
    end

    # rubocop:enable Metrics/ParameterLists

    def key
      "limber_#{@prefix.downcase.tr(' ', '_')}"
    end

    # Builds the corresponding request type, unless it
    # already exists.
    def build! # rubocop:todo Metrics/AbcSize
      rt =
        RequestType
          .create_with(
            name: "Limber #{@prefix}",
            request_class_name: @request_class,
            asset_type: 'Well',
            order: 1,
            initial_state: 'pending',
            billable: true,
            product_line: ProductLine.find_or_create_by!(name: @product_line),
            request_purpose: :standard,
            for_multiplexing: @for_multiplexing
          )
          .find_or_create_by!(key: key)

      rt.acceptable_plate_purposes = Purpose.where(name: @default_purposes)
      rt_lts = rt.library_types.pluck(:name)
      @library_types.each do |name|
        rt.library_types << LibraryType.find_or_create_by!(name: name) unless rt_lts.include?(name)
      end

      return true if rt.request_type_validators.exists?(request_option: 'library_type')

      RequestType::Validator.create!(
        request_type: rt,
        request_option: 'library_type',
        valid_options: RequestType::Validator::LibraryTypeValidator.new(rt.id)
      )
    end
  end

  # Construct submission templates for the Limber pipeline
  class TemplateConstructor
    include ActiveModel::Model

    # Required:
    # @attr [String] prefix The prefix for the given limber pipeline (eg. WGS)
    # @attr [ProductCatalogue] catalogue The product catalogue that matches the submission.
    #                           Note: Most limber stuff will use a simple SingleProduct catalogue with a product names after the prefix.

    # The following parameters are optional, and usually get calculated from the prefix.
    # @attr_writer [String] name Optional: The library creation portion of the submission template name
    #                            defaults to the prefix.
    # @attr_writer [String] type Optional: The library creation request key (eg. limber_wgs) for the templates.
    #                           Calculated from the prefix by default.
    # @attr_writer [String] role Optional: A string matching the desired order role. Defaults to the prefix.

    # The following are optional and change the range of submission templates constructed.
    # @attr_writer [Boolean] cherrypicked  Set to true to generate submission templates with in built cherrypicking.
    # @attr_writer [Array] sequencing_keys Array of sequencing request type keys to build templates for.
    #                                      Defaults to all appropriate request types.

    attr_accessor :prefix, :catalogue
    attr_writer :name, :type, :role, :cherrypicked, :sequencing_keys, :pipeline, :product_line

    #
    # Finds all submission templates matching the provided name.
    # If sequencing is not specified will find *all* submission templates.
    # @param name [String] The library creation portion of the {SubmissionTemplate} name
    # @param sequencing [Array<String>] Array of sequencing {RequestType#key} to find the templates for.
    #
    # @return [Array<SubmissionTemplate>] An array of all matching submission templates.
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

    def name
      @name || prefix
    end

    # The name or the {OrderRole} associated with the submission template. If {#role} is not specified
    # falls back to {#prefix}
    #
    # @return [String] The name of the order role used for the submission templates
    def role
      @role || prefix
    end

    #
    # Prefix before submission template names.
    # Defaults to {Limber::Helper::PIPELINE}
    #
    # @return [String] Prefix before submission template names.
    def pipeline
      @pipeline || PIPELINE
    end

    # The name of the {ProductLine} associated with the submission template.
    #
    # {include:ProductLine}
    #
    # If {#product_line} is not specified defaults to {PRODUCTLINE}
    #
    # @return [String] The name of the product line
    def product_line
      @product_line || PRODUCTLINE
    end

    # The {RequestType#key} of the {RequestType} that forms the library creation
    # part of the generated {SubmissionTemplate submission templates}.
    #
    # If {#type} is not specified, defaults to 'limber_' followed by {#prefix}
    #
    # @return [String] The key of the library creation {RequestType}
    def type
      @type || "limber_#{prefix.downcase.tr(' ', '_')}"
    end

    # The {RequestType#key} of the {RequestType request types} that forms the sequencing
    # part of the generated {SubmissionTemplate submission templates}.
    #
    # If {#sequencing_keys= sequencing_keys} is not specified, defaults to 'limber_' followed by {#prefix}
    #
    # @return [Array] All Sequencing RequestTypes for which a SubmissionTemplate will be generated
    def sequencing_request_types
      @sequencing_request_types ||= @sequencing_keys.map { |request| RequestType.find_by!(key: request) }
    end

    #
    # The name of the {SubmissionTemplate} for the given options.
    # @param cherrypick [Boolean] Whether there is a cherrypick component
    # @param sequencing_request_type [RequestType] The sequencing request type
    #
    # @return [String] A name for the request type
    def name_for(cherrypick, sequencing_request_type)
      "#{pipeline} - #{cherrypick ? 'Cherrypicked - ' : ''}#{name} - #{
        sequencing_request_type.name.gsub(PIPELINE_REGEX, '')
      }"
    end

    # Construct a series of {SubmissionTemplate submission templates} according to the specified options.
    # @see file:lib/tasks/limber.rake
    #
    # @example Generating PCR Free submission templates
    #   Limber::Helper::RequestTypeConstructor.new(
    #    'PCR Free',
    #    library_types: ['HiSeqX PCR free', 'PCR Free 384', 'Chromium single cell CNV', 'DAFT-seq'],
    #    default_purposes: ['PF Cherrypicked']
    #  ).build!
    def build!
      validate!
      each_submission_template { |config| SubmissionTemplate.create!(config) }
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
          next if SubmissionTemplate.exists?(name: name_for(cherrypick, sequencing_request_type))

          yield(
            {
              name: name_for(cherrypick, sequencing_request_type),
              submission_class_name: 'LinearSubmission',
              submission_parameters: submission_parameters(cherrypick, sequencing_request_type),
              product_line_id: product_line_id,
              product_catalogue: catalogue
            }
          )
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

  #
  # Class LibraryAndMultiplexingTemplateConstructor provides a template
  # constructor which build the library portion of the submission
  # template with the multiplexing request. No sequencing requests are added.
  #
  class LibraryAndMultiplexingTemplateConstructor < TemplateConstructor
    def name_for(cherrypick, _sequencing_request_type)
      "#{pipeline} - #{cherrypick ? 'Cherrypicked - ' : ''}#{name} - Pool"
    end

    def sequencing_request_types
      [nil]
    end

    def request_type_ids(cherrypick, _sequencing)
      ids = []
      ids << [cherrypick_request_type.id] if cherrypick
      ids << [library_request_type.id]
      ids << [multiplexing_request_type.id] unless library_request_type.for_multiplexing?
    end
  end
end
