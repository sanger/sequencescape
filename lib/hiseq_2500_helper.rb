# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014 Genome Research Ltd.
module Hiseq2500Helper
  def self.create_request_type(pl, ended = 'paired')
    RequestType.create!(
        key: "illumina_#{pl}_hiseq_2500_#{ended}_end_sequencing",
        name: "Illumina-#{pl.upcase} HiSeq 2500 #{ended.titleize} end sequencing",
        workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
        asset_type: 'LibraryTube',
        order: 2,
        initial_state: 'pending',
        multiples_allowed: true,
        request_class_name: 'HiSeqSequencingRequest',
        product_line: ProductLine.find_by(name: "Illumina-#{pl.upcase}")
      )
  end

  def self.template(settings)
    {
      name: settings[:name],
      product_line: ProductLine.find_by(name: "Illumina-#{settings[:pipeline].upcase}"),
      submission_class_name: 'LinearSubmission',
      submission_parameters: {
        workflow_id: 1,
        request_type_ids_list: request_types(settings),
        info_differential: 1
      }.merge(other(settings))
    }
  end

  def self.sequencing_request_type(settings)
    RequestType.find_by(key: "illumina_#{settings[:pipeline]}_hiseq_2500_#{settings[:ended] || 'paired'}_end_sequencing")
  end

  def self.library_request_type(settings)
    # Ugh, our production and seeded database differ
    RequestType.find_by(key: settings[:library_creation].first) || RequestType.find_by(key: settings[:library_creation].last)
  end

  def self.request_types(settings)
    rts = settings[:cherrypick] ? [[RequestType.find_by(key: settings[:cherrypick]).id]] : []
    rts << [library_request_type(settings).id] << [sequencing_request_type(settings).id]
  end

  def self.input_fields(sizes, libraries)
    [
      FieldInfo.new(kind: 'Text', default_value: '', parameters: {}, display_name: 'Fragment size required (from)', key: 'fragment_size_required_from'),
      FieldInfo.new(kind: 'Text', default_value: '', parameters: {}, display_name: 'Fragment size required (to)', key: 'fragment_size_required_to'),
      FieldInfo.new(
        kind: 'Selection', default_value: 'Standard', parameters: { selection: libraries },
        display_name: 'Library type',
        key: 'library_type'
      ),
      FieldInfo.new(kind: 'Selection', default_value: sizes.last, parameters: { selection: sizes }, display_name: 'Read length', key: 'read_length')
    ]
  end

  def self.other(settings)
    case settings[:sub_params]
    when :ill_c
      {}
    when :ill_c_single
      {}
    when :sc
      { request_options: { 'fragment_size_required_to' => '400', 'fragment_size_required_from' => '100', 'library_type' => 'Agilent Pulldown' } }
    when :wgs
      { request_options: { 'fragment_size_required_to' => '500', 'fragment_size_required_from' => '300', 'library_type' => 'Standard' } }
    when :ill_b
      {}
    when :ill_b_single
      {}
    else
      raise 'Invalid submission parameters'
    end
  end
end
