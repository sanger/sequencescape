class CherrypickTask < Task
  EMPTY_WELL = [0,"Empty",""]

  def create_render_element(request)
  end

  def map_empty_wells(template,plate)
    empty_wells = {}
    unless plate.nil?
      plate.children.each do |well|
        empty_wells[Map.description_to_horizontal_plate_position(well.map.description,well.map.asset_size)] = well.map.description
      end
    end

    template.children.each do |well|
      empty_wells[Map.pipelines_map_id_to_snp_map_id(well.map_id)] = well.map.description
    end
    return empty_wells
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
    Request.create(:asset => well, :target_asset => Well.create(:sample => well.sample, :name => well.sample.name))
  end

  def control_well_required?(partial_plate, template)
    return false if template.nil?
    unless partial_plate.nil?
      unless partial_plate.control_well_exists?
        if template.control_well?
          return true
        end
      end
    else
      if template.control_well?
        return true
      end
    end

    false
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

  def add_template_empty_wells(empty_wells, current_plate, num_wells)
    template_empty_well = [0,"---",""]
    while ! empty_wells[Map.vertical_to_horizontal(current_plate.size+1,num_wells)].nil?
      current_plate << template_empty_well
    end
    return current_plate
  end

  def add_empty_wells_to_end_of_plate(current_plate, num_wells)
    while current_plate.size < num_wells
      current_plate << EMPTY_WELL
    end
    return current_plate
  end

  def add_plate_id_to_source_plates(source_plates,plate_id)
    if source_plates[plate_id].nil?
      source_plates[plate_id] =1
    else
      source_plates[plate_id] +=1
    end
    return source_plates
  end

  def map_wells_to_plates(requests, template, robot, batch, partial_plate)
    control_well_required = control_well_required?(partial_plate, template)
    num_wells = template.size

    empty_wells = map_empty_wells(template,partial_plate)
    max_plates = robot_max_plates(robot)
    plates_hash = build_plate_wells_from_requests(requests,num_wells)

    plates =[]
    source_plates = {}
    source_plate_index = {}
    current_plate = []
    control = false

    plates_hash.sort.each do |pid,plate|
      plate.sort.each do |mid,well|
        if current_plate.size >= num_wells
          plates << current_plate
          current_plate = []
          control = false
          source_plate_index = source_plate_index.merge(source_plates)
          source_plates = {}
        end
        current_plate = add_template_empty_wells(empty_wells, current_plate,num_wells)

        if current_plate.size >= num_wells
          plates << current_plate
          current_plate = []
          control = false
          source_plate_index = source_plate_index.merge(source_plates)
          source_plates ={}
        end

        if current_plate.size > (num_wells-empty_wells.size)/2 && (control_well_required)
          unless control
            control = true
            current_plate << create_control_request_view_details(batch, partial_plate, template)
            current_plate = add_template_empty_wells(empty_wells, current_plate,num_wells)
          end
        end

        source_plates = add_plate_id_to_source_plates(source_plates,pid)

        if source_plates.size >=max_plates
          current_plate = add_empty_wells_to_end_of_plate(current_plate, num_wells)
          plates << current_plate
          current_plate = []
          control = false
          source_plate_index = source_plate_index.merge(source_plates)
          source_plates ={}
        end

        current_plate << [well[0],pid,well[1]]
      end
    end

    if current_plate.size > 0 && current_plate.size <= num_wells
      if  (! control) && control_well_required
        current_plate = add_template_empty_wells(empty_wells, current_plate,num_wells)
        control = true
        current_plate << create_control_request_view_details(batch, partial_plate, template)
      end
      current_plate = add_empty_wells_to_end_of_plate(current_plate, num_wells)
      plates << current_plate
    end

    if control_well_required
      source_plates = add_plate_id_to_source_plates(source_plates,ControlPlate.first.barcode)
    end
    source_plate_index = source_plate_index.merge(source_plates)

    [plates,source_plate_index.keys]
  end

  def build_plate_wells_from_requests(requests,num_wells)
    plates = {}
    requests.each do |request|
      plate_id = request.asset.plate.barcode
      if plates[plate_id].nil?
        plates[plate_id] = {}
      end
      charnum_well = Map.find(request.asset.map_id).description
      vert_map_id = Map.description_to_vertical_plate_position(charnum_well,num_wells)
      plates[plate_id][vert_map_id] = [request.id, charnum_well, vert_map_id, plate_id]
    end
    plates
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

end
