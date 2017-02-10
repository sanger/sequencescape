# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

class AssignTagsToWellsTask < Task
  include Request::GroupingHelpers

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
    'assign_tags_to_wells_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_assign_tags_to_wells_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_assign_tags_to_wells_task(self, params)
  end

  def assign_tags_to_wells(requests, well_id_tag_id_map)
    # If the tubes have been processed they will have aliquots.  That means that this is a retagging
    # operation, otherwise we're initially tagging.
    have_tagged_tubes_already = requests.map(&:target_asset).uniq.all? { |tube| not tube.aliquots.empty? }
    have_tagged_tubes_already ? retag_tubes(requests, well_id_tag_id_map) : tag_tubes(requests, well_id_tag_id_map)
  end

  def retag_tubes(requests, well_id_tag_id_map)
    # The first thing we do is build a graph of the transfers that have been made so that we can
    # clean it out.  The assets themselves cannot be rebuilt as people may be relying on the assets
    # remaining consistent.
    source_well_to_intermediate_wells, requests_to_destroy = {}, []
    requests.each do |request|
      source_well, target_tube = request.asset, request.target_asset

      source_to_library = source_well.requests_as_source.where_is_a?(TransferRequest).first
      library_well      = source_to_library.target_asset

      library_to_tagged = library_well.requests_as_source.where_is_a?(TransferRequest).first
      tagged_well       = library_to_tagged.target_asset

      tagged_to_pooled  = tagged_well.requests_as_source.where_is_a?(TransferRequest).first
      pooled_well       = tagged_to_pooled.target_asset

      requests_to_destroy.concat([source_to_library, library_to_tagged, tagged_to_pooled])
      requests_to_destroy.concat(pooled_well.requests_as_source.where_is_a?(TransferRequest).all)

      source_well_to_intermediate_wells[source_well] = [library_well, tagged_well, pooled_well, target_tube]
    end
    requests_to_destroy.uniq.map(&:destroy)

    # Now we can clean out the aliquots of all of the various assets and rebuild the graph so that the
    # correct tags are in place.
    pooled_well_to_tube = {}
    source_well_to_intermediate_wells.values.flatten.uniq.each { |well| well.aliquots.clear }
    source_well_to_intermediate_wells.each do |source_well, assets|
      library_well, tagged_well, pooled_well, tube = assets

      RequestType.transfer.create!(asset: source_well, target_asset: library_well, state: 'passed')
      library_well.aliquots.each { |aliquot| aliquot.update_attributes!(library: library_well) }

      RequestType.transfer.create!(asset: library_well, target_asset: tagged_well, state: 'passed')
      tag_id = well_id_tag_id_map[source_well.id]
      Tag.find(tag_id).tag!(tagged_well) if tag_id.present?

      RequestType.transfer.create!(asset: tagged_well, target_asset: pooled_well, state: 'passed')

      raise StandardError, 'Pooled well into different tube!' unless tube == (pooled_well_to_tube[pooled_well] || tube)
      pooled_well_to_tube[pooled_well] = tube
    end

    pooled_well_to_tube.each { |well, tube| RequestType.transfer.create!(asset: well, target_asset: tube) }
  end
  private :retag_tubes

  def tag_tubes(requests, well_id_tag_id_map)
    # to  be compliant with the new pulldown application we have to create intermediate plate and wells
    source_plates = requests.map(&:asset).map(&:plate).uniq
    raise StandardError, 'Can only tag based on one source plate' unless source_plates.size == 1
    source_plate = source_plates.first

    well_to_tagged = {}
    tube_to_pool = {}

    pooled_plate  = Plate.create!(size: source_plate.size)
    library_plate = Plate.create!(size: source_plate.size)
    tag_plate     = Plate.create!(size: source_plate.size)

    source_plate.wells.each do |well|
      library_well = Well.create!
      RequestType.transfer.create!(asset: well, target_asset: library_well, state: 'passed')
      library_plate.add_well_by_map_description(library_well, well.map_description)
      library_well.aliquots.each { |aliquot| aliquot.update_attributes!(library: library_well) }

      tagged_well = Well.create!
      well_to_tagged[well] = tagged_well
      RequestType.transfer.create!(asset: library_well, target_asset: tagged_well, state: 'passed')
      tag_plate.add_well_by_map_description(tagged_well, well.map_description)
      tag_id = well_id_tag_id_map[well.id]
      Tag.find(tag_id).tag!(tagged_well) if tag_id
    end
    [library_plate, tag_plate].map(&:save!)

    # We could be retagging because someone has changed their minds.
    requests.each { |request| request.target_asset.aliquots.clear }

    requests.each do |r|
      tagged_well = well_to_tagged[r.asset]
      raise 'Well not tagged' if tagged_well.nil?
      tube = r.target_asset

      pooled_well = tube_to_pool[tube]
      unless pooled_well
        pooled_well = Well.create!
        tube_to_pool[tube] = pooled_well
        pooled_plate.add_well_by_map_description(pooled_well, tagged_well.map_description)
      end

      RequestType.transfer.create!(asset: tagged_well, target_asset: pooled_well, state: 'passed')
      # transfer between pooled_well and tube needs to be at the end, when all the aliquots are present
      # RequestType.transfer.create!(:asset => pooled_well, :target_asset => tube)
    end

    tube_to_pool.each do |tube, pooled_well|
      RequestType.transfer.create!(asset: pooled_well, target_asset: tube, state: 'passed')
    end

    link_pulldown_indexed_libraries_to_multiplexed_library(requests)
  end
  private :tag_tubes

  def validate_returned_tags_are_not_repeated_in_submission!(requests, params)
    submission_to_tag = params[:tag].map do |well_id, tag_id|
      well_requests = requests.select { |request| request.asset_id == well_id.to_i }
      raise 'couldnt find matching well request' if well_requests.empty? || well_requests.first.nil?
      [well_requests.first.submission_id, tag_id]
    end
    raise 'Duplicate tags in single multiplex' if submission_to_tag != submission_to_tag.uniq

    nil
  end

  def create_tag_instances_and_link_to_wells(_requests, params)
    params[:tag].map do |well_id, tag_id|
      ActiveRecord::Base.transaction do
        Tag.find(tag_id).tag!(Well.find(well_id))
      end
    end
  end

  def find_sequencing_requests(pulldown_requests)
    Request.where(submission_id: pulldown_requests.first.submission_id).select { |sequencing_request| sequencing_request.is_a?(SequencingRequest) }
  end

  def link_pulldown_indexed_libraries_to_multiplexed_library(requests)
    group_requests_by_submission_id(requests).each do |requests_with_same_submission|
      sequencing_requests = find_sequencing_requests(requests_with_same_submission)
      raise 'Couldnt find sequencing request' if sequencing_requests.empty?

      # If the requests don't all end in the same tube!
      raise 'Borked!' unless requests_with_same_submission.map(&:target_asset).compact.uniq.size == 1
      sequencing_requests.each { |sequencing_request| sequencing_request.update_attributes!(asset: requests_with_same_submission.first.target_asset) }
    end
  end

  def validate_tags_not_repeated_for_submission!(requests, tags_to_wells)
    submission_to_tag = requests.select { |request| request.asset }.map { |request| [request.submission_id, tags_to_wells[request.asset.map.description].map_id] }
    raise 'Duplicate tags will be assigned to a pooled tube' if submission_to_tag != submission_to_tag.uniq

    nil
  end

  def unlink_tag_instances_from_wells(requests)
    requests.each do |request|
      request.asset.untag!
    end
  end

  def map_tags_to_wells(tag_group, plate)
    tags_to_wells = {}
    wells = plate.wells_sorted_by_map_id
    sorted_tags = tag_group.tags_sorted_by_map_id
    current_well = wells.first

    1.upto(plate.size) do |index|
      tags_to_wells[Map::Coordinate.vertical_plate_position_to_description(index, plate.size)] = sorted_tags[(index - 1) % sorted_tags.size]
    end

    tags_to_wells
  end

  def find_plates_from_batch(batch_id)
    requests = find_batch_requests(batch_id)
    plates = requests.select { |request| request.asset.is_a?(Well) }.map { |request| request.asset }.map { |asset| asset.plate }.select { |plate| plate }
    plates.first
  end

  def map_asset_ids_to_normalised_index_by_submission(requests)
    submissions_to_index = {}
    asset_ids_to_index = {}
    requests.map { |request| request.submission_id }.uniq.each_with_index { |submission_id, index| submissions_to_index[submission_id] = index }
    requests.map { |request| asset_ids_to_index[request.asset_id] = submissions_to_index[request.submission_id] }

    asset_ids_to_index
  end
end
