# frozen_string_literal: true

# An instance of this class represents the target plate being picked onto.  It can have a template
# and be a partial plate, and so when wells are picked into it we need to ensure that we don't hit
# the template/partial wells.
class CherrypickTask::PickTarget
  def self.for(plate_purpose)
    cherrypick_direction = plate_purpose.nil? ? 'column' : plate_purpose.cherrypick_direction
    const_get("by_#{cherrypick_direction}".classify)
  end

  # Base class for different pick target beha
  class Base
    def initialize(template, asset_shape = nil, partial = nil)
      @wells = []
      @size = template.size
      @shape = asset_shape || AssetShape.default
      initialize_already_occupied_wells_from(template, partial)
      add_any_wells_from_template_or_partial(@wells)
    end

    delegate :empty?, to: :@wells

    def content
      @wells
    end

    attr_reader :size

    def full?
      @wells.size == @size
    end

    # Creates control requests for the control assets provided and adds them to the batch
    def create_control_requests!(batch, control_assets)
      control_requests =
        control_assets.map do |control_asset|
          CherrypickRequest.create(
            asset: control_asset,
            target_asset: Well.new,
            submission: batch.requests.first.submission,
            request_type: batch.requests.first.request_type,
            request_purpose: 'standard'
          )
        end
      batch.requests << control_requests
      control_requests
    end

    # Creates a new control request for the control_asset and adds it into the current_destination_plate plate
    def add_control_request(batch, control_asset)
      control_request = create_control_requests!(batch, [control_asset]).first
      control_request.start!
      push(control_request.id, control_request.asset.plate.human_barcode, control_request.asset.map_description)
    end

    # Adds any consecutive list of control requests into the current_destination_plate
    def add_any_consecutive_control_requests(control_posns, batch, control_assets)
      # find the index of the well we are filling right now
      current_well_index = content.length

      # check if this well should contain a control
      # add it if so, and any consecutive ones by looping
      while control_posns.include?(current_well_index)
        control_asset = control_assets[control_posns.find_index(current_well_index)]
        add_control_request(batch, control_asset)

        # above adds to current_destination_plate, so current_well_index should be recalculated
        current_well_index = content.length
      end
    end

    # Adds any remaining control requests not already added, into the current_destination_plate plate
    def add_remaining_control_requests(control_posns, batch, control_assets)
      control_posns.each_with_index do |pos, idx|
        if pos >= content.length
          control_asset = control_assets[idx]
          add_control_request(batch, control_asset)
        end
      end
    end

    def push(request_id, plate_barcode, well_location)
      @wells << [request_id, plate_barcode, well_location]

      add_any_wells_from_template_or_partial(@wells)
      self
    end

    # includes control wells and template / partial wells that are yet to be added
    def remaining_wells(control_posns)
      remaining_controls = control_posns.select { |c| c > @wells.length }
      remaining_used_wells = @used_wells.keys.select { |c| c > @wells.length }
      remaining_controls.concat(remaining_used_wells).flatten
    end

    # rubocop:todo Metrics/ParameterLists
    def push_with_controls(request_id, plate_barcode, well_location, control_posns, batch, control_assets)
      # rubocop:enable Metrics/ParameterLists
      @wells << [request_id, plate_barcode, well_location]
      if control_posns
        # would be nil if no control plate selected
        add_any_consecutive_control_requests(control_posns, batch, control_assets)

        # This assumes that the template wells will fall at the end of the plate
        if (@wells.length + remaining_wells(control_posns).length) == @size
          add_remaining_control_requests(control_posns, batch, control_assets)
        end
      end
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
      @used_wells =
        {}.tap do |wells|
          [partial, template].compact.each do |plate|
            plate.wells.each { |w| wells[w.map.horizontal_plate_position] = w.map.description }
          end
        end
    end
    private :initialize_already_occupied_wells_from

    # Every time a well is added to the pick we need to make sure that the template and partial are
    # checked to see if subsequent wells are already taken.  In other words, after calling this method
    # the next position on the pick plate is known to be empty.
    def add_any_wells_from_template_or_partial(wells)
      wells << CherrypickTask::TEMPLATE_EMPTY_WELL until (wells.size >= @size) || @used_wells[well_position(wells)].nil?
    end
    private :add_any_wells_from_template_or_partial

    def add_empty_well(wells)
      wells << CherrypickTask::EMPTY_WELL
    end
    private :add_empty_well

    # When starting a new plate, it writes all control requests from the beginning of the plate
    def add_any_initial_control_requests(control_posns, batch, control_assets)
      current_well_index = content.length
      control_posns
        .select { |c| c <= current_well_index }
        .each do |control_well_index|
          control_asset = control_assets[control_posns.find_index(control_well_index)]
          add_control_request(batch, control_asset)
        end
      add_any_consecutive_control_requests(control_posns, batch, control_assets)
    end
  end

  # Deals with generating the pick plate by travelling in a row direction, so A1, A2, A3 ...
  class ByRow < Base
    def well_position(wells)
      (wells.size + 1) > @size ? nil : wells.size + 1
    end
    private :well_position

    def completed_view
      @wells
        .dup
        .tap { |wells| complete(wells) }
        .each_with_index
        .inject([]) do |wells, (well, index)|
          wells.tap { wells[@shape.horizontal_to_vertical(index + 1, @size)] = well }
        end
        .compact
    end
  end

  # Deals with generating the pick plate by travelling in a column direction, so A1, B1, C1 ...
  class ByColumn < Base
    def well_position(wells)
      @shape.vertical_to_horizontal(wells.size + 1, @size)
    end
    private :well_position

    def completed_view
      @wells.dup.tap { |wells| complete(wells) }
    end
  end

  # Deals with generating the pick plate by travelling in an interlaced column direction, so A1, C1, E1 ...
  class ByInterlacedColumn < Base
    def well_position(wells)
      @shape.interlaced_vertical_to_horizontal(wells.size + 1, @size)
    end
    private :well_position

    def completed_view
      @wells
        .dup
        .tap { |wells| complete(wells) }
        .each_with_index
        .inject([]) do |wells, (well, index)|
          wells.tap { wells[@shape.vertical_to_interlaced_vertical(index + 1, @size)] = well }
        end
        .compact
    end
  end
end
