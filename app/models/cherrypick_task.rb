class CherrypickTask < Task
  EMPTY_WELL = [0,"Empty",""]

  def create_render_element(request)
  end

  def robot_max_plates(robot)
    return 0 if robot.nil?
    robot.max_beds
  end

  def create_control_request(batch, partial_plate, template)
    return nil unless control_well_required?(partial_plate, template)
    control_plate = ControlPlate.first
    control_wells = control_plate.illumina_wells
    selected_well = control_wells.sample
    request = generate_control_request(selected_well)
    batch.requests << request

    request
  end

  def generate_control_request(well)
    # TODO: create a genotyping request for the control request
    #Request.create(:state => "pending", :sample => well.sample, :asset => well, :target_asset => Well.create(:sample => well.sample, :name => well.sample.name))
    target_well = Well.create!(:name => well.primary_aliquot.sample.name, :aliquots => well.aliquots.map(&:clone))
    workflow.pipeline.request_type.create_control!(:asset => well, :target_asset => target_well)
  end

  def get_well_from_control_param(control_param)
    control_param.scan(/([\d]+)/)
    well_id = $1.to_i
    Well.find_by_id(well_id)
  end

  def create_control_request_from_well(control_param)
    return nil unless control_param.match(/control/)
    well = get_well_from_control_param(control_param)
    return nil if well.nil?
    self.generate_control_request(well)
  end

  def create_control_request_view_details(batch, partial_plate, template)
    control_request = create_control_request(batch, partial_plate, template)
    return nil if control_request.nil?
    return [control_request.id,control_request.asset.parent.barcode,control_request.asset.map.description]
  end

  TEMPLATE_EMPTY_WELL = [0,'---','']

  def add_template_empty_wells(empty_wells, current_plate, num_wells)
    while ! empty_wells[Map.vertical_to_horizontal(current_plate.size+1,num_wells)].nil?
      current_plate << TEMPLATE_EMPTY_WELL
    end
    return current_plate
  end

  def map_wells_to_plates(requests, template, robot, batch, partial_plate)
    max_plates = robot_max_plates(robot)
    raise StandardError, 'The chosen robot has no beds!' if max_plates.zero?

    control_well_required = control_well_required?(partial_plate, template)
    num_wells = template.size

    empty_wells = map_empty_wells(template,partial_plate)
    plates_hash = build_plate_wells_from_requests(requests)

    plates =[]
    source_plates = Set.new
    current_plate = []
    control = false

    push_completed_plate = lambda do
      plates << current_plate.dup
      current_plate.clear
      control = false
    end

    plates_hash.each do |request_id, plate_barcode, well_location|
      push_completed_plate.call if current_plate.size >= num_wells

      add_template_empty_wells(empty_wells, current_plate,num_wells)

      push_completed_plate.call if current_plate.size >= num_wells

      if !control and current_plate.size > (num_wells-empty_wells.size)/2 && (control_well_required)
        control = true
        current_plate << create_control_request_view_details(batch, partial_plate, template)
        add_template_empty_wells(empty_wells, current_plate,num_wells)
      end

      source_plates << plate_barcode

      if (source_plates.size % max_plates).zero?
        add_empty_wells_to_end_of_plate(current_plate, num_wells)
        push_completed_plate.call
      end

      current_plate << [request_id, plate_barcode, well_location]
    end

    if current_plate.size > 0 && current_plate.size <= num_wells
      if  (! control) && control_well_required
        add_template_empty_wells(empty_wells, current_plate,num_wells)
        control = true
        current_plate << create_control_request_view_details(batch, partial_plate, template)
      end
      current_plate = add_empty_wells_to_end_of_plate(current_plate, num_wells)
      plates << current_plate
    end

    source_plates << ControlPlate.first.barcode if control_well_required

    [plates,source_plates]
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

  # STUFF I HAVE TIDIED:

  def map_empty_wells(template,plate)
    {}.tap do |empty_wells|
      empty_wells.merge!(Hash[plate.wells.map { |w| [w.map.horizontal_plate_position,w.map.description] }]) unless plate.nil?
      empty_wells.merge!(Hash[template.wells.map { |w| [w.map.snp_id, w.map.description] }])
    end
  end
  private :map_empty_wells

  def build_plate_wells_from_requests(requests)
    requests.sort do |left, right|
      sorted = left.asset.plate.barcode <=> right.asset.plate.barcode
      sorted = left.asset.map.vertical_plate_position <=> right.asset.map.vertical_plate_position if sorted.zero?
      sorted
    end.map do |request|
      [request.id, request.asset.plate.barcode, request.asset.map.description]
    end
  end
  private :build_plate_wells_from_requests

  def control_well_required?(partial_plate, template)
    return false if template.nil?
    return template.control_well? if partial_plate.nil?
    return !partial_plate.control_well_exists? && template.control_well?
  end
  private :control_well_required?

  def add_empty_wells_to_end_of_plate(current_plate, num_wells)
    current_plate.concat([ EMPTY_WELL ] * (num_wells - current_plate.size))
  end
  private :add_empty_wells_to_end_of_plate
end
