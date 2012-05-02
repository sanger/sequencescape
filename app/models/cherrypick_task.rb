class CherrypickTask < Task
  EMPTY_WELL = [0,"Empty",""]

  def create_render_element(request)
  end

  def generate_control_request(well)
    # TODO: create a genotyping request for the control request
    #Request.create(:state => "pending", :sample => well.sample, :asset => well, :target_asset => Well.create(:sample => well.sample, :name => well.sample.name))
    target_well = Well.create!(:name => well.primary_aliquot.sample.name, :aliquots => well.aliquots.map(&:clone))
    workflow.pipeline.request_type.create_control!(:asset => well, :target_asset => target_well)
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

  def map_wells_to_plates(requests, template, robot, batch, partial_plate)
    max_plates = robot.max_beds
    raise StandardError, 'The chosen robot has no beds!' if max_plates.zero?

    control_well_required = control_well_required?(partial_plate, template)
    empty_wells = map_empty_wells(template,partial_plate)
    plates_hash = build_plate_wells_from_requests(requests)

    num_wells = template.size
    plates =[]
    source_plates = Set.new
    current_plate, current_sources = [], Set.new
    control = false

    push_completed_plate = lambda do
      plates << current_plate.dup
      current_plate.clear
      current_sources.clear
      control = false

      # Reset the control well information
      partial_plate = nil
      control_well_required = control_well_required?(nil, template)
      empty_wells = map_empty_wells(template, nil)
    end
    fill_plate_and_push = lambda do
      add_empty_wells_to_end_of_plate(current_plate, num_wells)
      push_completed_plate.call
    end

    plates_hash.each do |request_id, plate_barcode, well_location|
      push_completed_plate.call if current_plate.size >= num_wells

      add_template_empty_wells(empty_wells, current_plate,num_wells)

      push_completed_plate.call if current_plate.size >= num_wells

      if !control and control_well_required and current_plate.size > (num_wells-empty_wells.size)/2
        control = true
        create_control_request_view_details(batch, partial_plate, template) { |c| current_plate << c }
        add_template_empty_wells(empty_wells, current_plate,num_wells)
      end

      # Doing this here ensures that the plate_barcode being processed will be the first
      # well on the new plate.
      unless current_sources.include?(plate_barcode)
        fill_plate_and_push.call if not current_sources.empty? and (current_sources.size % max_plates).zero? and not current_plate.empty?
        source_plates   << plate_barcode
        current_sources << plate_barcode
      end

      current_plate << [request_id, plate_barcode, well_location]
    end

    if current_plate.size > 0 && current_plate.size <= num_wells
      if !control and control_well_required
        add_template_empty_wells(empty_wells, current_plate,num_wells)
        control = true
        create_control_request_view_details(batch, partial_plate, template) { |c| current_plate << c }
      end
      fill_plate_and_push.call
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

  def control_well_required?(partial_plate, template)
    template.present? && template.control_well? && (partial_plate.nil? || !partial_plate.control_well_exists?)
  end
  private :control_well_required?

  def add_empty_wells_to_end_of_plate(current_plate, num_wells)
    current_plate.concat([ EMPTY_WELL ] * (num_wells - current_plate.size))
  end
  private :add_empty_wells_to_end_of_plate

  def create_control_request_view_details(batch, partial_plate, template, &block)
    create_control_request(batch, partial_plate, template) do |control_request|
      yield([control_request.id,control_request.asset.parent.barcode,control_request.asset.map.description])
    end
  end
  private :create_control_request_view_details

  def create_control_request(batch, partial_plate, template, &block)
    raise StandardError, "Did not expect request for control well" unless control_well_required?(partial_plate, template)

    generate_control_request(ControlPlate.first.illumina_wells.sample).tap do |request|
      batch.requests << request
      yield(request)
    end
  end
  private :create_control_request

  TEMPLATE_EMPTY_WELL = [0,'---','']

  def add_template_empty_wells(empty_wells, current_plate, num_wells)
    current_plate << TEMPLATE_EMPTY_WELL until empty_wells[Map.vertical_to_horizontal(current_plate.size+1, num_wells)].nil?
  end
  private :add_template_empty_wells
end
