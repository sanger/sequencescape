class Parsers::QuantParser
  class InvalidFile < StandardError; end

  def initialize(content)
    @content = content
  end

  def each_well_and_parameters

  end

  def concentration(plate_position)
  end

  def method_set_list
    binding.pry
    @content[(@content.find_index{|l| l[0] == 'Headers'}+1)].map do |description|
      {
        #"Well Location" => :set_location,
        "Concentration" => :set_concentration
        #"RIN" => :set_rin
      }[description]
    end
  end

  def values_for_location(location)
    Hash[method_set_list.zip(@content.find{|w| w[0]==location}).reject{|header, value| header.nil?}]
  end

  def update_values_for(plate)
    plate.wells.each do |well|
      location = well.map.description
      well.update_values_from_object(values_for_location(location))
    end
  end

  def self.is_quant_file?(content)
    content[0][0] == 'Assay Plate Barcode'
  end
end
