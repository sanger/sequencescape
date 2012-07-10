module IlluminaBPlatePurposes
  # We only have one flow at the moment
  def self.create_plate_purposes
    IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS.each do |flow|

      stock_plate = create_stock_purpose(flow.shift)

      IlluminaB::PlatePurposes.request_type_for(stock_plate).acceptable_plate_purposes  << stock_plate

      flow.inject(stock_plate) do |previous,plate_purpose_name|
        create_purpose(plate_purpose_name).tap do |new_purpose|
          previous.child_relationships.create!(:child => new_purpose, :transfer_request_type => request_type_for(previous, new_purpose))
        end
      end
    end

    IlluminaB::PlatePurposes::BRANCHES.each do |parent,child|
      parent_purpose, new_purpose = PlatePurpose.find_by_name(parent), create_purpose(child)
      parent_purpose.child_relationships.create!(:child => new_purpose, :transfer_request_type => request_type_for(parent_purpose, new_purpose))
    end
  end

  def self.request_type_for(parent, child)
    _, _, request_class = IlluminaB::PlatePurposes::PLATE_PURPOSES_TO_REQUEST_CLASS_NAMES.detect { |a,b,_| (parent.name == a) && (child.name == b) }
    return RequestType.transfer if request_class.nil?
    request_type_name = "Illumina-B #{parent.name}-#{child.name}"
    RequestType.create!(:name => request_type_name, :key => request_type_name.gsub(/\W+/, '_'), :request_class_name => request_class, :asset_type => 'Well', :order => 1)
  end

  def self.create_purpose(plate_purpose_name)
    IlluminaB::PlatePurposes::PLATE_PURPOSE_TYPE[plate_purpose_name].create!(
      :name => plate_purpose_name,
      :cherrypickable_target => false,
      :cherrypick_direction => IlluminaB::PlatePurposes.plate_direction
      ).tap do |plate_purpose|
        plate_purpose.barcode_printer_type = BarcodePrinterType.find_by_type('BarcodePrinterType96Plate')||plate_purpose.barcode_printer_type
      end
  end

  def self.create_stock_purpose(plate_purpose_name)
    IlluminaB::PlatePurposes.stock_plate_class.create!(
      :name => plate_purpose_name,
      :can_be_considered_a_stock_plate => true,
      :default_state => 'passed',
      :cherrypickable_target => true,
      :cherrypick_direction => IlluminaB::PlatePurposes.plate_direction
      ).tap do |plate_purpose|
        plate_purpose.barcode_printer_type = BarcodePrinterType.find_by_type('BarcodePrinterType96Plate')||plate_purpose.barcode_printer_type
      end
  end
end
