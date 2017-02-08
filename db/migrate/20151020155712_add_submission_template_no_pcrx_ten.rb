# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
require 'submission_serializer'

class AddSubmissionTemplateNoPcrxTen < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do |_t|
      st = SubmissionSerializer.construct!(name: 'Illumina-C - General no PCR - HiSeq-X sequencing',
                                           submission_class_name: 'LinearSubmission',
                                           product_line: 'Illumina-C',
                                           submission_parameters: {
          request_types: ['illumina_c_nopcr', 'illumina_b_hiseq_x_paired_end_sequencing'],
          workflow: 'short_read_sequencing'
        })
      lt = LibraryType.find_or_create_by(name: 'HiSeqX PCR free')
      rt = RequestType.find_by(key: 'illumina_c_nopcr').library_types << lt
      ['illumina_a_hiseq_x_paired_end_sequencing', 'illumina_b_hiseq_x_paired_end_sequencing'].each do |xtlb_name|
        RequestType.find_by(key: xtlb_name).library_types << lt
      end

      tag_group = TagGroup.find_by(name: 'NEXTflex-96 barcoded adapters') || TagGroup.first

      TagLayoutTemplate.create!(
        name: 'NEXTflex-96 barcoded adapters tags in rows (first oligo: AACGTGAT)',
        direction_algorithm: 'TagLayout::InRows',
        walking_algorithm: 'TagLayout::WalkWellsOfPlate',
        tag_group: tag_group
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do |_t|
      hiseqlt = LibraryType.find_by(name: 'HiSeqX PCR free')
      unless hiseqlt.nil?
        ['illumina_c_nopcr', 'illumina_a_hiseq_x_paired_end_sequencing', 'illumina_b_hiseq_x_paired_end_sequencing'].each do |rt_name|
          rt = RequestType.find_by(key: rt_name)
          lib_types = rt.library_types
          unless lib_types.nil?
            rt.library_types = lib_types.reject { |lt| lt == hiseqlt }
          end
        end
        hiseqlt.destroy
      end
      TagLayoutTemplate.find_by(name: 'NEXTflex-96 barcoded adapters tags in rows (first oligo: AACGTGAT)').destroy
      SubmissionTemplate.find_by(name: 'Illumina-C - General no PCR - HiSeq-X sequencing').destroy
    end
  end
end
