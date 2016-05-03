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

  def localization_text(attribute_name)
    I18n.t("metadata.well.metadata.#{attribute_name}.label")
  end

  def method_set_list
    headers_section.map do |description|
      {
        localization_text("concentration").strip.downcase => :set_concentration
      }[description.strip.downcase]
    end
  end

  def values_for_location(location)
    data_list = @content.find{|w| w[0]==location}
    Hash[method_set_list.zip(data_list).reject{|header, value| header.nil?}] unless data_list.nil?
  end

  def valid_float_value_update(v)
    # If it is nil, we won't update anything. We are just indicating that it is considered a valid input
    v.nil? || v.downcase.strip.match(/^\d/)
  end

  def update_values_for(plate)
    plate.wells.each do |well|
      location = well.map.description
      updated_data = values_for_location(location)
      unless updated_data.nil? || !(updated_data.values.all?{|v| valid_float_value_update(v) })
        well.update_values_from_object(updated_data)
      end
    end
  end

  def self.is_quant_file?(content)
    (content[0][0] == 'Assay Plate Barcode') && self.headers_index(content)
  end
end
