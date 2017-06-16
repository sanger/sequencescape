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
    def initialize(suffix,
      request_class: DEFAULT_REQUEST_CLASS,
      library_types: DEFAULT_LIBRARY_TYPES,
      default_purpose: DEFAULT_PURPOSE)
      @suffix = suffix
      @request_class = request_class
      @library_types = library_types
      @default_purpose = default_purpose
    end

    def key
      "limber_#{@suffix.downcase.tr(' ', '_')}"
    end

    # Builds the corresponding request type, unless it
    # already exists.
    def build!
      return true if RequestType.where(key: key).exists?

      rt = RequestType.create!(
        name: "Limber #{@suffix}",
        key: key,
        request_class_name: @request_class,
        for_multiplexing: false,
        workflow: Submission::Workflow.find_by(name: 'Next-gen sequencing'),
        asset_type: 'Well',
        order: 1,
        initial_state: 'pending',
        billable: true,
        product_line: ProductLine.find_by(name: PRODUCTLINE),
        request_purpose: RequestPurpose.standard
      ) do |rt|
        rt.acceptable_plate_purposes << Purpose.find_by!(name: @default_purpose)
        rt.library_types = LibraryType.where(name: @library_types)
      end

      RequestType::Validator.create!(
        request_type: rt,
        request_option: 'library_type',
        valid_options: RequestType::Validator::LibraryTypeValidator.new(rt.id)
      )
    end
  end

  class TemplateConstructor
    # Construct submission templates for the generic pipeline
    # opts is a hash
    # {
    #   :name => The Name for the Library Step
    #   :sequencing => Optional array of sequencing request type keys. Default is all.
    #   :role => The role that will be printed on barcodes
    #   :type => 'illumina_c_pcr'||'illumina_c_nopcr'
    # }
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

    def initialize(params)
      self.name = params[:name]
      self.type = params[:type]
      self.role = params[:role]
      self.skip_cherrypick = params.fetch(:skip_cherrypick, true)
      self.sequencing = params[:sequencing] || ACCEPTABLE_SEQUENCING_REQUESTS
      self.catalogue = params[:catalogue]
    end

    def sequencing=(sequencing_array)
      @sequencing = sequencing_array.map do |request|
        RequestType.find_by!(key: request)
      end
    end

    def validate!
      [:name, :type, :role, :catalogue].each do |value|
        raise "Must provide a #{value}" if send(value).nil?
      end
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
        workflow_id: Submission::Workflow.find_by(key: 'short_read_sequencing').id,
        order_role_id: Order::OrderRole.find_or_create_by(role: role).id,
        info_differential: Submission::Workflow.find_by(key: 'short_read_sequencing').id
      }
    end
  end
end
