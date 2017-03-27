# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015 Genome Research Ltd.

module IlluminaC::Helper
  require 'hiseq_2500_helper'

  ACCEPTABLE_REQUEST_TYPES = %w(illumina_c_pcr illumina_c_nopcr illumina_c_multiplexing illumina_c_chromium_library)
  ACCEPTABLE_SEQUENCING_REQUESTS = %w(
    illumina_c_single_ended_sequencing
    illumina_c_paired_end_sequencing
    illumina_c_hiseq_paired_end_sequencing
    illumina_c_single_ended_hi_seq_sequencing
    illumina_c_miseq_sequencing
    illumina_c_hiseq_v4_paired_end_sequencing
    illumina_c_hiseq_v4_single_end_sequencing
    illumina_c_hiseq_2500_paired_end_sequencing
    illumina_c_hiseq_2500_single_end_sequencing
    illumina_c_hiseq_4000_paired_end_sequencing
    illumina_c_hiseq_4000_single_end_sequencing
  )

  PIPELINE = 'Illumina-C'
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

    def initialize(params)
      self.name = params[:name]
      self.type = params[:type]
      self.role = params[:role]
      self.skip_cherrypick = params[:skip_cherrypick]
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
      raise "Request Type should be #{ACCEPTABLE_REQUEST_TYPES.join(', ')}" unless ACCEPTABLE_REQUEST_TYPES.include?(type)
      true
    end

    def name_for(cherrypick, sequencing_request_type)
      "#{PIPELINE} - #{cherrypick ? 'Cherrypicked - ' : ''}#{name} - #{sequencing_request_type.name.gsub("#{PIPELINE} ", '')}"
    end

    def build!
      validate!
      each_submission_template do |config|
        SubmissionTemplate.create!(config)
      end
    end

    def library_request_type
      @library_request_type ||= RequestType.find_by!(key: type)
    end

    def cherrypick_request_type
      RequestType.find_by!(key: 'cherrypick_for_illumina_c')
    end

    def multiplexing_request_type
      RequestType.find_by!(key: 'illumina_c_multiplexing')
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
          yield({
            name: name_for(cherrypick, sequencing_request_type),
            submission_class_name: 'LinearSubmission',
            submission_parameters: submission_parameters(cherrypick, sequencing_request_type),
            product_line_id: ProductLine.find_by(name: PIPELINE).id,
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

    def update!
      each_submission_template do |options|
        next if options[:submission_parameters][:input_field_infos].nil?
        SubmissionTemplate.find_by!(name: options[:name]).update_attributes!(submission_parameters: options[:submission_parameters])
      end
    end

    def self.find_for(name, sequencing = nil)
      tc = TemplateConstructor.new(name: name, sequencing: sequencing)
      [true, false].map do |cherrypick|
        tc.sequencing.map do |sequencing_request_type|
          SubmissionTemplate.find_by!(name: tc.name_for(cherrypick, sequencing_request_type))
        end
      end.flatten
    end
  end
end
