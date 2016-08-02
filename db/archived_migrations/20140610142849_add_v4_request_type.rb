#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddV4RequestType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ['a', 'b', 'c'].each do |pipeline|
        RequestType.create!({
          :key => "illumina_#{pipeline}_hiseq_v4_paired_end_sequencing",
          :name => "Illumina-#{pipeline.upcase} HiSeq V4 Paired end sequencing",
          :workflow =>  Submission::Workflow.find_by_key("short_read_sequencing"),
          :asset_type => "LibraryTube",
          :order => 2,
          :initial_state => "pending",
          :request_class_name => "HiSeqSequencingRequest",
          :billable => true,
          :product_line => ProductLine.find_by_name("Illumina-#{pipeline.upcase}")
        })
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ['a', 'b', 'c'].each do |pipeline|
        RequestType.find_by_key("illumina_#{pipeline}_hiseq_v4_paired_end_sequencing").destroy
      end
    end
  end
end
