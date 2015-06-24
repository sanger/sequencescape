#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class HiseqXPipelineDoesntCloneRequest < ActiveRecord::Migration

  class Pipeline < ActiveRecord::Base
    set_table_name('pipelines')
  end

  def self.up
    Pipeline.find_by_name(['HiSeq X PE (spiked in controls) from strip-tubes','HiSeq X PE (spiked in controls) Striptube']).update_attributes!(:sti_type=>'UnrepeatableSequencingPipeline')
  end

  def self.down
     Pipeline.find_by_name(['HiSeq X PE (spiked in controls) from strip-tubes','HiSeq X PE (spiked in controls) Striptube']).update_attributes!(:sti_type=>'SequencingPipeline')
  end
end
