# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

class CherrypickTask < Task
  EMPTY_WELL          = [0, 'Empty', '']
  TEMPLATE_EMPTY_WELL = [0, '---', '']

  def create_render_element(request)
  end

  class BatchWrapper
    def initialize(owner, batch)
      @owner, @batch, @control_added = owner, batch, false
    end

    def control_added?
      @control_added
    end

    def create_control_request_view_details
      # NOTE: 'sample' here is not a Sequencescape sample but a random selection from the wells.
      @owner.send(:generate_control_request, ControlPlate.first.illumina_wells.sample).tap do |request|
        @batch.requests << request
        yield([request.id, request.asset.plate.barcode, request.asset.map.description])
        @control_added = true
      end
    end
  end

  # An instance of this class represents the target plate being picked onto.  It can have a template
  # and be a partial plate, and so when wells are picked into it we need to ensure that we don't hit
  # the template/partial wells.
  class PickTarget
    def self.for(plate_purpose)
      cherrypick_direction = plate_purpose.nil? ? 'column' : plate_purpose.cherrypick_direction
      const_get("by_#{cherrypick_direction}".classify)
    end

    def initialize(batch, template, asset_shape = nil, partial = nil)
      @wells, @size, @batch, @shape = [], template.size, batch, asset_shape || AssetShape.default
      initialize_already_occupied_wells_from(template, partial)
      add_any_wells_from_template_or_partial(@wells)
    end

    # Deals with generating the pick plate by travelling in a row direction, so A1, A2, A3 ...
    class ByRow < PickTarget
      def well_position(wells)
        (wells.size + 1) > @size ? nil : wells.size + 1
      end
      private :well_position

      def completed_view
        @wells.dup.tap do |wells|
          complete(wells)
        end.each_with_index.inject([]) do |wells, (well, index)|
          wells.tap { wells[@shape.horizontal_to_vertical(index + 1, @size)] = well }
        end.compact
      end
    end

    # Deals with generating the pick plate by travelling in a column direction, so A1, B1, C1 ...
    class ByColumn < PickTarget
      def well_position(wells)
         @shape.vertical_to_horizontal(wells.size + 1, @size)
      end
      private :well_position

      def completed_view
        @wells.dup.tap { |wells| complete(wells) }
      end
    end

    # Deals with generating the pick plate by travelling in an interlaced column direction, so A1, C1, E1 ...
    class ByInterlacedColumn < PickTarget
      def well_position(wells)
         @shape.interlaced_vertical_to_horizontal(wells.size + 1, @size)
      end
      private :well_position

      def completed_view
        @wells.dup.tap do |wells|
          complete(wells)
        end.each_with_index.inject([]) do |wells, (well, index)|
          wells.tap { wells[@shape.vertical_to_interlaced_vertical(index + 1, @size)] = well }
        end.compact
      end
    end

    def empty?
      @wells.empty?
    end

    def full?
      @wells.size == @size
    end

    def push(request_id, plate_barcode, well_location)
      @wells << [request_id, plate_barcode, well_location]
      add_any_wells_from_template_or_partial(@wells)
      self
    end

    # Completes the given well array such that it looks like the plate has been completely picked.
    def complete(wells)
      until wells.size >= @size
        add_empty_well(wells)
        add_any_wells_from_template_or_partial(wells)
      end
    end
    private :complete

    # Determines the wells that are already occupied on the template or the partial plate.  This is
    # then used in add_any_wells_from_template_or_partial to fill them in as wells are added by the
    # pick.
    def initialize_already_occupied_wells_from(template, partial)
      @used_wells = {}.tap do |wells|
        [partial, template].compact.each do |plate|
          plate.wells.each { |w| wells[w.map.horizontal_plate_position] = w.map.description }
        end
      end

      @control_well_required = template.control_well? && (partial.nil? || !partial.control_well_exists?)
    end
    private :initialize_already_occupied_wells_from

    # Every time a well is added to the pick we need to make sure that the template and partial are
    # checked to see if subsequent wells are already taken.  In other words, after calling this method
    # the next position on the pick plate is known to be empty.
    def add_any_wells_from_template_or_partial(wells)
      wells << CherrypickTask::TEMPLATE_EMPTY_WELL until wells.size >= @size or @used_wells[well_position(wells)].nil?
      return unless @control_well_required and wells.size == (@size - 1)

      # Control well is always in the bottom right corner of the plate
      @batch.create_control_request_view_details do |control_request_view|
        wells << control_request_view
        @control_well_required = false
      end
    end
    private :add_any_wells_from_template_or_partial

    def add_empty_well(wells)
      wells << CherrypickTask::EMPTY_WELL
    end
    private :add_empty_well
  end

  def pick_new_plate(requests, template, robot, batch, plate_purpose)
    target_type = PickTarget.for(plate_purpose)
    perform_pick(requests, robot, batch) do |batch|
      target_type.new(batch, template, plate_purpose.try(:asset_shape))
    end
  end

  def pick_onto_partial_plate(requests, template, robot, batch, partial_plate)
    purpose = partial_plate.plate_purpose
    target_type = PickTarget.for(purpose)

    perform_pick(requests, robot, batch) do |batch|
      target_type.new(batch, template, purpose.try(:asset_shape), partial_plate).tap do
        partial_plate = nil # Ensure that subsequent calls have no partial plate
      end
    end
  end

  def perform_pick(requests, robot, batch)
    max_plates = robot.max_beds
    raise StandardError, 'The chosen robot has no beds!' if max_plates.zero?

    batch                          = BatchWrapper.new(self, batch)
    plates, current_plate          = [], yield(batch)
    source_plates, current_sources = Set.new, Set.new
    plates_hash                    = build_plate_wells_from_requests(requests)

    push_completed_plate = lambda do
      plates << current_plate.completed_view
      current_sources.clear
      current_plate = yield(batch)
    end

    plates_hash.each do |request_id, plate_barcode, well_location|
      # Doing this here ensures that the plate_barcode being processed will be the first
      # well on the new plate.
      unless current_sources.include?(plate_barcode)
        push_completed_plate.call if not current_sources.empty? and (current_sources.size % max_plates).zero? and not current_plate.empty?
        source_plates   << plate_barcode
        current_sources << plate_barcode
      end

      # Add this well to the pick and if the plate is filled up by that push it to the list.
      current_plate.push(request_id, plate_barcode, well_location)
      push_completed_plate.call if current_plate.full?
    end

    # Ensure that a non-empty plate is stored and that the control plate is added if it has been used
    push_completed_plate.call unless current_plate.empty?
    source_plates << ControlPlate.first.barcode if batch.control_added?

    [plates, source_plates]
  end
  private :perform_pick

  def partial
    'cherrypick_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_cherrypick_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_cherrypick_task(self, params)
  rescue Cherrypick::Error => exception
    workflow.send(:flash)[:error] = exception.message
    return false
  end

  def build_plate_wells_from_requests(requests)
    Request.select(['requests.id AS id', 'plates.barcode AS barcode', 'maps.description AS description'])
      .joins([
        'INNER JOIN assets wells ON requests.asset_id=wells.id',
        'INNER JOIN container_associations ON container_associations.content_id=wells.id',
        'INNER JOIN assets plates ON plates.id=container_associations.container_id',
        'INNER JOIN maps ON wells.map_id=maps.id'
      ])
      .order('plates.barcode ASC, maps.column_order ASC')
      .where(requests: { id: requests })
      .all.map do |request|
      [request.id, request.barcode, request.description]
    end
  end
  private :build_plate_wells_from_requests

  def generate_control_request(well)
    # TODO: create a genotyping request for the control request
    # Request.create(:state => "pending", :sample => well.sample, :asset => well, :target_asset => Well.create(:sample => well.sample, :name => well.sample.name))
    workflow.pipeline.control_request_type.create_control!(
      asset: well,
      target_asset: Well.create!(aliquots: well.aliquots.map(&:dup))
    )
  end
  private :generate_control_request

  def get_well_from_control_param(control_param)
    control_param.scan(/([\d]+)/)
    well_id = $1.to_i
    Well.find_by(id: well_id)
  end
  private :get_well_from_control_param

  def create_control_request_from_well(control_param)
    return nil unless control_param =~ /control/
    well = get_well_from_control_param(control_param)
    return nil if well.nil?
    generate_control_request(well)
  end
end
