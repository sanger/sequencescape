class FixPulldownGraph < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      #batched first
      process_batched_requests()
      # unbatched requests need to be done at the end to not be processed by the previous
      create_tube_for_unbatched_requests()
      #raise "redo"
    end
  end
  def self.process_batched_requests()
    plate_to_child = {}
    PulldownMultiplexedLibraryCreationRequest.with_target.group_by(&:submission).each do |submission, requests|
      # check asset target are the same t
      case
      when requests.all? { |r| r.target_asset.is_a?(Well) } 
        process_unfinished_batch(submission, requests)
      when requests.all? { |r| r.target_asset.is_a?(PulldownMultiplexedLibraryTube) } 
        process_completed_batch(submission, requests, plate_to_child)
      else
        raise "submission '#{submission.id}' have mixed request target"
      end
    end
  end

  def self.process_unfinished_batch(submission, requests)
    puts "unfinished #{submission.inspect}. skipped"
  end

  def self.process_completed_batch(submission, requests, plate_to_child)
    puts "process submission #{submission.id}"
    #return if [8691, 12336, 12337].include?(submission.id)
    #return if submission.id > 12000
    #return unless submission.id == 12337
    #puts "doing in real for #{submission.id}"
    pooled_well = nil
    requests.each do |request|
      source = request.asset
      tube = request.target_asset
      well_chain = [source]
      tag_instance = source.tag_instance
      source.children.delete(tag_instance) 
      raise "well #{source.id} hasn't the expected number of child" if source.children.size != 1
      library_well = source.children.first

      # Library
      source_plate = source.plate
      if library_plate=plate_to_child[source_plate] 
        # the plate has already been copied, we just need to find the corresponding well
        raise "wrong parent well for well #{library_well.id}" if library_well != library_plate.find_well_by_map_description(source.map_description)
      else
        # we create a Plate without well, as the wells already exist
        library_plate = plate_to_child[source_plate] = Plate.create!(:size => source_plate.size).tap do |new_plate|
          source_plate.children << new_plate
          # we add all the needed wells
          # we considere that all the wells of the initial plate, share the same destiny
          source_plate.wells.each do |well|
            tag_instance = well.tag_instance
            children = Array(well.children)
            children.delete(tag_instance) 
            if children.size != 1
              puts "well #{well.id} hasn't the expected number of child" if children.size != 1
            end
            new_well = children.first
            if new_well.plate
              puts "well #{new_well.id} is already in plate #{new_well.plate.id}"
            else
            new_plate.add_well_by_map_description(new_well, well.map_description)
            end
            #break
          end
        end
      end
      well_chain << library_well

      # Tagged 
      tagged_plate = plate_to_child[library_plate] ||=  library_plate.create_child 
      tagged_well = tagged_plate.find_well_by_map_description(source.map_description)
      if tagged_well
      if tag_instance
      tag_instance.children << tagged_well
      well_chain << tagged_well
      else
        puts "no tag found for well #{source.id}"
      end
      else
        puts "not tagged well found for well #{source.id}"
      end


      #all the well of the same submission go in the pooled well
      pooled_well ||= begin
                        pooled_plate = plate_to_child[tagged_plate] ||=  tagged_plate.create_child 
                        pooled_well = pooled_plate.find_well_by_map_description(source.map_description)
                      end
      well_chain << pooled_well
      well_chain << tube unless pooled_well.requests.any?{ |r| r.target_asset == tube }

      well_chain.inject(well_chain.shift){ |s,t| TransfertRequest.create!(:asset => s, :target_asset => t) }
    end

  end

  def self.create_tube_for_unbatched_requests()
    helper_task = AssignTagsToWellsTask.new
    PulldownMultiplexedLibraryCreationRequest.without_target.group_by(&:submission).each do |submission, requests|
      #next unless submission.id == 13073
      helper_task.link_pulldown_indexed_libraries_to_multiplexed_library(requests)
    end
  end

  def self.down
  end
end
