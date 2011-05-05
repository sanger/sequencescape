class AssignTagsToWellsTask < Task

  class AssignTagsToWellsData < Task::RenderElement
    alias_attribute :well, :asset
    def initialize(request)
      super(request)
    end
  end

  def create_render_element(request)
    request.asset && AssignTagsToWellsData.new(request)
  end

  def partial
    "assign_tags_to_wells_batches"
  end

  def render_task(workflow, params)
    super
    workflow.render_assign_tags_to_wells_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_assign_tags_to_wells_task(self, params)
  end

  def validate_returned_tags_are_not_repeated_in_submission!(requests, params)
    submission_to_tag = params[:tag].map do |well_id, tag_id|
      well_requests = requests.select{|request| request.asset_id == well_id.to_i}
      raise "couldnt find matching well request" if well_requests.empty? || well_requests.first.nil?
      [well_requests.first.submission_id, tag_id]
    end
    raise "Duplicate tags in single multiplex" if submission_to_tag != submission_to_tag.uniq

    nil
  end

  def create_tag_instances_and_link_to_wells(requests, params)
    params[:tag].map do |well_id, tag_id|
      ActiveRecord::Base.transaction do     
        well = Well.find(well_id)
        if well.tag_instance.nil?
          tag = Tag.find(tag_id)
          tag_instance  = TagInstance.create!(:tag => tag)
          AssetLink.connect(well, tag_instance)
        else
          raise "Unable to add multiple tags to a well."
        end
      end
    end
  end

  def find_sequencing_requests(pulldown_requests)
    Request.find_all_by_submission_id(pulldown_requests.first.submission_id).select{ |sequencing_request| sequencing_request.is_a?(SequencingRequest) }
  end

  def link_pulldown_indexed_libraries_to_multiplexed_library(requests)
    CherrypickGroupBySubmissionTask.new.group_requests_by_submission_id(requests).each do |requests_with_same_submission|
      sequencing_requests = find_sequencing_requests(requests_with_same_submission)
      raise 'Couldnt find sequencing request' if sequencing_requests.empty?
      initial_sequencing_request = sequencing_requests.pop
      initial_sequencing_request.create_assets_for_multiplexing if initial_sequencing_request.asset.nil? && initial_sequencing_request.target_asset.nil?

      # allow for multiple lanes of the same library
      sequencing_requests.each do |sequencing_request|
        sequencing_request.update_attributes!(:asset => initial_sequencing_request.asset, :target_asset => initial_sequencing_request.target_asset)
      end
      
      requests_with_same_submission.each do |request|
        request.update_attributes!(:target_asset => initial_sequencing_request.asset)
      end
    end
  end

  def validate_tags_not_repeated_for_submission!(requests, tags_to_wells)
    submission_to_tag = requests.select{ |request| request.asset }.map{ |request| [request.submission_id, tags_to_wells[request.asset.map.description].map_id ] }
    raise "Duplicate tags will be assigned to a pooled tube" if submission_to_tag != submission_to_tag.uniq

    nil
  end

  def unlink_tag_instances_from_wells(requests)
    requests.each do |request|
      asset = request.asset
      tag_instance = asset.tag_instance
      next unless tag_instance
      asset.children.delete(tag_instance)
      asset.save!
    end
  end

  def map_tags_to_wells(tag_group, plate)
    tags_to_wells = {}
    wells = plate.wells_sorted_by_map_id
    sorted_tags = tag_group.tags_sorted_by_map_id
    current_well = wells.first

    1.upto(plate.size) do |index|
      tags_to_wells[Map.vertical_plate_position_to_description(index, plate.size)] = sorted_tags[(index-1) % sorted_tags.size]
    end

    tags_to_wells
  end

  def find_plates_from_batch(batch_id)
    requests = find_batch_requests(batch_id)
    plates = requests.select{ |request| request.asset.is_a?(Well) }.map{ |request| request.asset }.map{ |asset| asset.plate }.select{ |plate| plate }
    plates.first
  end

  def map_asset_ids_to_normalised_index_by_submission(requests)
    submissions_to_index = {}
    asset_ids_to_index = {}
    requests.map{|request| request.submission_id }.uniq.each_with_index{ |submission_id, index| submissions_to_index[submission_id] = index }
    requests.map{|request| asset_ids_to_index[request.asset_id] = submissions_to_index[request.submission_id] }
    
    asset_ids_to_index
  end



end
