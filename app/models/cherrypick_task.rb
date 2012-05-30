class CherrypickTask < Task
  EMPTY_WELL          = [0,"Empty",""]
  TEMPLATE_EMPTY_WELL = [0,'---','']

  def create_render_element(request)
  end

  class BatchWrapper
    def initialize(owner, batch)
      @owner, @batch, @control_added = owner, batch, false
    end

    def control_added?
      @control_added
    end

    def create_control_request_view_details(&block)
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
    def initialize(batch, template, partial)
      @wells, @size, @batch = [], template.size, batch
      initialize_already_occupied_wells_from(template, partial)
      add_any_wells_from_template_or_partial(@wells)
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

    # Returns an array that represents the complete pick plate as it would be at the current time.
    # This is not necessarily the final version, as you can continue to pick to the plate, but it is
    # a snapshot in time.
    def completed_view
      @wells.dup.tap { |wells| complete(wells) }
    end

    # Completes the given well array such that it looks like the plate has been completely picked.
    def complete(wells)
      until wells.size == @size
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
        partial.wells.each  { |w| wells[w.map.horizontal_plate_position] = w.map.description } unless partial.nil?
        template.wells.each { |w| wells[w.map.snp_id] = w.map.description }
      end
      @control_well_required = template.control_well? && (partial.nil? || !partial.control_well_exists?)
    end
    private :initialize_already_occupied_wells_from

    # Every time a well is added to the pick we need to make sure that the template and partial are
    # checked to see if subsequent wells are already taken.  In other words, after calling this method
    # the next position on the pick plate is known to be empty.
    def add_any_wells_from_template_or_partial(wells)
      wells << CherrypickTask::TEMPLATE_EMPTY_WELL until wells.size == @size or @used_wells[Map.vertical_to_horizontal(wells.size+1, @size)].nil?
      return unless @control_well_required and wells.size == (@size-1)

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

  def map_wells_to_plates(requests, template, robot, batch, partial_plate)
    max_plates = robot.max_beds
    raise StandardError, 'The chosen robot has no beds!' if max_plates.zero?

    batch                          = BatchWrapper.new(self, batch)
    plates, current_plate          = [], PickTarget.new(batch, template, partial_plate)
    source_plates, current_sources = Set.new, Set.new
    plates_hash                    = build_plate_wells_from_requests(requests)

    push_completed_plate = lambda do
      plates << current_plate.completed_view
      current_sources.clear
      current_plate = PickTarget.new(batch, template, nil)
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

  def partial
    "cherrypick_batches"
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

  def self.parse_uploaded_spreadsheet_layout(layout_data,plate_size)
    parsed_plates = {}
    source_plate_index = {}
    begin
      FasterCSV.parse(layout_data) do |row|
        well_layout = self.parse_spreadsheet_row(row,plate_size)
        next if well_layout.nil?
        plate_key, request_id, index_of_well_on_plate = well_layout
        if parsed_plates[plate_key].nil?
          parsed_plates[plate_key] = {}
        end
        parsed_plates[plate_key][index_of_well_on_plate] = request_id
      end
    rescue
      raise FasterCSV::MalformedCSVError
      return nil
    end

    parsed_plates
  end

  def self.parse_spreadsheet_row(row,plate_size)
    return nil if row.blank?
    request_id,asset_name,plate_key,destination_well = row
    return nil if request_id.blank? || request_id.to_i == 0
    if plate_key.blank?
      plate_key = "default plate 1"
    end
    return nil if destination_well.blank? || destination_well.to_i > 0
    return nil if Map.find_by_description_and_asset_size(destination_well,plate_size).nil?
    index_of_well_on_plate = Map.description_to_vertical_plate_position(destination_well,plate_size)
    return nil if index_of_well_on_plate.nil?

    return [plate_key, request_id.to_i, index_of_well_on_plate]
  end

  def self.generate_spreadsheet(batch)
    csv_string = FasterCSV.generate( :row_sep => "\r\n") do |csv|
      csv << ["Request ID","Sample Name","Plate","Destination Well"]
      batch.requests.each{ |r| csv << [r.id,r.asset.sample.name,"",""]}
    end
  end

  def self.map_parsed_spreadsheet_to_plate(mapped_plate_wells,batch,plate_size)
    plates = []
    source_plate_index = {}
    mapped_plate_wells.each do |plate_key, mapped_wells|
      current_plate = []
      1.upto(plate_size) do |i|
        if mapped_wells[i]
          begin
            source_plate_barcode = batch.requests.find(mapped_wells[i]).asset.plate.barcode
            unless source_plate_index[source_plate_barcode]
              source_plate_index[source_plate_barcode] = 1
            end
            current_plate << [mapped_wells[i], source_plate_barcode, Map.vertical_plate_position_to_description(i,plate_size)]
          rescue
            current_plate << EMPTY_WELL
          end
        else
          current_plate << EMPTY_WELL
        end
      end
      plates << current_plate
    end

    [plates,source_plate_index.keys]
  end

  def build_plate_wells_from_requests(requests)
    Request.all(
      :select => 'requests.id AS id, plates.barcode AS barcode, maps.description AS description',
      :joins => [
        'INNER JOIN assets wells ON requests.asset_id=wells.id',
        'INNER JOIN container_associations ON container_associations.content_id=wells.id',
        'INNER JOIN assets plates ON plates.id=container_associations.container_id',
        'INNER JOIN maps ON wells.map_id=maps.id'
      ],
      :order => 'plates.barcode ASC, maps.column_order ASC',
      :conditions => { :requests => { :id => requests.map(&:id) } }
    ).map do |request|
      [request.id, request.barcode, request.description]
    end
  end
  private :build_plate_wells_from_requests

  def generate_control_request(well)
    # TODO: create a genotyping request for the control request
    #Request.create(:state => "pending", :sample => well.sample, :asset => well, :target_asset => Well.create(:sample => well.sample, :name => well.sample.name))
    target_well = Well.create!(:name => well.primary_aliquot.sample.name, :aliquots => well.aliquots.map(&:clone))
    workflow.pipeline.control_request_type.create_control!(:asset => well, :target_asset => target_well)
  end
  private :generate_control_request

  def get_well_from_control_param(control_param)
    control_param.scan(/([\d]+)/)
    well_id = $1.to_i
    Well.find_by_id(well_id)
  end
  private :get_well_from_control_param

  def create_control_request_from_well(control_param)
    return nil unless control_param.match(/control/)
    well = get_well_from_control_param(control_param)
    return nil if well.nil?
    generate_control_request(well)
  end
end
