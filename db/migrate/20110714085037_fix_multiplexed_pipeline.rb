class FixMultiplexedPipeline < ActiveRecord::Migration
  def self.up
    do_it
  end
  def  self.do_it
    MultiplexedLibraryTube.all.each do |mx_tube|
      next if mx_tube.source_request
      mx_tube.parents.each do |parent|
        next unless parent.is_a?(LibraryTube)

        TransfertRequest.create!(:asset => parent, :target_asset => mx_tube, :state => 'passed')
      end
    end
  end

  def self.down
  end
end
