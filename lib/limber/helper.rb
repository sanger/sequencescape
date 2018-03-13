# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015 Genome Research Ltd.

module Limber::Helper
  require 'hiseq_2500_helper'

  ACCEPTABLE_SEQUENCING_REQUESTS = %w(
    illumina_b_hiseq_2500_paired_end_sequencing
    illumina_b_hiseq_2500_single_end_sequencing
    illumina_b_miseq_sequencing
    illumina_b_hiseq_v4_paired_end_sequencing
    illumina_b_hiseq_x_paired_end_sequencing
    illumina_htp_hiseq_4000_paired_end_sequencing
    illumina_htp_hiseq_4000_single_end_sequencing
  )

  PIPELINE = 'Limber-Htp'
  PIPELINE_REGEX = /Illumina-[A-z]{1,3} /
  PRODUCTLINE = 'Illumina-Htp'
  DEFAULT_REQUEST_CLASS = 'IlluminaHtp::Requests::StdLibraryRequest'
  DEFAULT_LIBRARY_TYPES = ['Standard']
  DEFAULT_PURPOSE = 'LB Cherrypick'

  class RequestTypeConstructor
    def initialize(prefix,
                   request_class: DEFAULT_REQUEST_CLASS,
                   library_types: DEFAULT_LIBRARY_TYPES,
                   default_purpose: DEFAULT_PURPOSE,
                   for_multiplexing: false)
      @prefix = prefix
      @request_class = request_class
      @library_types = library_types
      @default_purpose = default_purpose
      @for_multiplexing = for_multiplexing
    end

    def key
      "limber_#{@prefix.downcase.tr(' ', '_')}"
    end

    # Builds the corresponding request type, unless it
    # already exists.
    def build!
      return true if RequestType.where(key: key).exists?
      rt = RequestType.create!(
        name: "Limber #{@prefix}",
        key: key,
        request_class_name: @request_class,
        asset_type: 'Well',
        order: 1,
        initial_state: 'pending',
        billable: true,
        product_line: ProductLine.find_by(name: PRODUCTLINE),
        request_purpose: :standard,
        for_multiplexing: @for_multiplexing
      ) do |rt|
        rt.acceptable_plate_purposes << Purpose.find_by!(name: @default_purpose)
        rt.library_types = @library_types.map { |name| LibraryType.find_or_create_by(name: name) }
      end

      RequestType::Validator.create!(
        request_type: rt,
        request_option: 'library_type',
        valid_options: RequestType::Validator::LibraryTypeValidator.new(rt.id)
      )
    end
  end

  class TemplateConstructor
    attr_accessor :name, :type, :role, :catalogue
    attr_reader :sequencing, :cherrypick_options

    def self.find_for(name, sequencing = nil)
      tc = TemplateConstructor.new(name: name, sequencing: sequencing)
      [true, false].map do |cherrypick|
        tc.sequencing.map do |sequencing_request_type|
          SubmissionTemplate.find_by!(name: tc.name_for(cherrypick, sequencing_request_type))
        end
      end.flatten
    end

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
    # @param [String] skip_cherrypick: true Boolean. Set to false to generate submission templates with in built cherrypicking.
    # @param [Array] sequencing: Array of sequencing request type keys to build templates for. Defaults to all appropriate request types.
    def initialize(name: nil, type: nil, role: nil, prefix: nil, skip_cherrypick: true, sequencing: ACCEPTABLE_SEQUENCING_REQUESTS, catalogue:)
      @name = name
      @type = type
      @role = role
      self.prefix = prefix
      self.skip_cherrypick = skip_cherrypick
      self.sequencing = sequencing
      @catalogue = catalogue
    end

    def prefix=(prefix)
      @name ||= prefix
      @role ||= prefix
      @type ||= "limber_#{prefix.downcase}"
    end

    def sequencing=(sequencing_array)
      @sequencing = sequencing_array.map do |request|
        RequestType.find_by!(key: request)
      end
    end

    def validate!
      [:name, :type, :role].each do |value|
        raise "Must provide a #{value} or prefix" if send(value).nil?
      end
      raise 'Must provide a catalogue' if catalogue.nil?
      true
    end

    def name_for(cherrypick, sequencing_request_type)
      "#{PIPELINE} - #{cherrypick ? 'Cherrypicked - ' : ''}#{name} - #{sequencing_request_type.name.gsub(PIPELINE_REGEX, '')}"
    end

    def build!
      validate!
      each_submission_template do |config|
        SubmissionTemplate.create!(config)
      end
    end

    def update!
      each_submission_template do |options|
        next if options[:submission_parameters][:input_field_infos].nil?
        SubmissionTemplate.find_by!(name: options[:name]).update_attributes!(submission_parameters: options[:submission_parameters])
      end
    end

    private

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

    def skip_cherrypick=(skip)
      @cherrypick_options = skip ? [false] : [true, false]
    end

    def each_submission_template
      cherrypick_options.each do |cherrypick|
        sequencing.each do |sequencing_request_type|
          next if SubmissionTemplate.where(name: name_for(cherrypick, sequencing_request_type)).exists?
          yield({
            name: name_for(cherrypick, sequencing_request_type),
            submission_class_name: 'LinearSubmission',
            submission_parameters: submission_parameters(cherrypick, sequencing_request_type),
            product_line_id: ProductLine.find_by(name: PRODUCTLINE).id,
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
      "#{PIPELINE} - #{cherrypick ? 'Cherrypicked - ' : ''}#{name}"
    end

    def sequencing
      [nil]
    end

    def request_type_ids(cherrypick, _sequencing)
      ids = []
      ids << [cherrypick_request_type.id] if cherrypick
      ids << [library_request_type.id]
    end
  end
end
