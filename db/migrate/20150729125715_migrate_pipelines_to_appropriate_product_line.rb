#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class MigratePipelinesToAppropriateProductLine < ActiveRecord::Migration

  class RequestType < ActiveRecord::Base
    self.table_name = 'request_types'
  end

  def self.request_type_product_line
    {
      "illumina_a_hiseq_paired_end_sequencing"=>"Illumina-A",
      "illumina_b_hiseq_paired_end_sequencing"=>"Illumina-B",
      "illumina_a_single_ended_hi_seq_sequencing"=>"Illumina-A",
      "illumina_b_single_ended_hi_seq_sequencing"=>"Illumina-B",
      "illumina_a_hiseq_2500_paired_end_sequencing"=>"Illumina-A",
      "illumina_b_hiseq_2500_paired_end_sequencing"=>"Illumina-B",
      "illumina_a_hiseq_2500_single_end_sequencing"=>"Illumina-A",
      "illumina_b_hiseq_2500_single_end_sequencing"=>"Illumina-B",
      "illumina_b_shared"=>"Illumina-B",
      "illumina_b_pool"=>"Illumina-B",
      "illumina_a_shared"=>"Illumina-A",
      "illumina_a_isc"=>"Illumina-A",
      "illumina_a_miseq_sequencing"=>"Illumina-A",
      "illumina_b_miseq_sequencing"=>"Illumina-B",
      "illumina_a_hiseq_v4_paired_end_sequencing"=>"Illumina-A",
      "illumina_b_hiseq_v4_paired_end_sequencing"=>"Illumina-B",
      "illumina_b_hiseq_x_paired_end_sequencing"=>"Illumina-B",
      "illumina_a_re_isc"=>"Illumina-A",
      "illumina_htp_library_creation"=>"Illumina-B",
      "illumina_htp_strip_tube_creation"=>"Illumina-B",
      "hiseq_x_paired_end_sequencing"=>"Illumina-B"
    }
  end

  def self.up
    ActiveRecord::Base.transaction do
      ihtp = ProductLine.find_by_name("Illumina-HTP")||ProductLine.create!(:name=>"Illumina-HTP")
      request_type_product_line.each do |key,old_line|
        rt = RequestType.find_by_key(key)
        if rt.nil?
          say "Skipping #{rt}"
          next
        end
        rt.update_attributes!(:product_line_id=>ihtp.id)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      request_type_product_line.each do |key,old_line|
        rt =RequestType.find_by_key(key)
        if rt.nil?
          say "Skipping #{rt}"
          next
        end
        rt.update_attributes!(:product_line_id=>ProductLine.find_by_name!(old_line).id)
      end
    end
  end
end
