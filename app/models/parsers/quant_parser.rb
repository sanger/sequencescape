class Parsers::QuantParser
  class InvalidFile < StandardError; end

  def initialize(content)
    @content = content
  end

  def self.headers_index(content)
    content.find_index{|l| l[0] == 'Headers'}
  end

  def headers_section
    @content[self.class.headers_index(@content)+1]
  end

  def data_section
    @content.slice(self.class.headers_index(@content)+2, @content.length)
  end

  def localization_text(attribute_name)
    I18n.t(:label,scope:[:metadata,:well,:metadata,attribute_name],default:attribute_name)
  end

  def column_maps
   @column_maps ||=  {
      "concentration" => :set_concentration,
      "volume"        => :set_current_volume,
      "rin"           => :set_rin
    }.merge({
      localization_text("concentration").strip.downcase => :set_concentration,
      localization_text("volume").strip.downcase        => :set_current_volume,
      localization_text("rin").strip.downcase           => :set_rin
    })
  end

  def method_set_list
    headers_section.map do |description|
      next if description.blank?
      column_maps[description.strip.downcase]
    end
  end

  def data_list(location)
    @content.find{|w| w[0]==location}
  end

  def qc_values_for_location(location)
    Hash[method_set_list.zip(data_list(location)).reject{|header, value| header.nil?}] unless data_list(location).nil?
  end

  def self.is_quant_file?(content)
    (content[0][0] == 'Assay Plate Barcode') && self.headers_index(content)
  end

  def each_well_and_parameters
    data_section.each do |line|
      yield(line[0], qc_values_for_location(line[0]))
    end
  end

end
