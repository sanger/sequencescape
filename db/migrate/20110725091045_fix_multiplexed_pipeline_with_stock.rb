#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class FixMultiplexedPipelineWithStock < ActiveRecord::Migration
  def self.up
    StockMultiplexedLibraryTube.all.each do |stock|
      tubes = stock.children.select { |c| c.is_a?(MultiplexedLibraryTube) }
      next if tubes.size != 1
      mx_tube = tubes.first

      stock.parents.select { |p| p.source_request.is_a?(MultiplexedLibraryCreationRequest) }.each do |library|
      TransfertRequest.create!(:asset => library , :target_asset => mx_tube, :state => 'passed')
      end
    end
  end

  def self.down
  end
end
