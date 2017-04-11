xml.instruct!
xml.request(api_data) {
  xml.id @request.id
  xml.created_at @request.created_at
  xml.updated_at @request.updated_at
  xml.sample_id @request.samples.first.id if @request.samples.size == 1
  xml.template @request.request_type.name, id: @request.request_type.id if @request.request_type
  xml.read_length(@request.request_metadata.read_length) unless @request.request_metadata.read_length.blank?
	xml.asset_id @request.asset_id if @request.asset
	xml.target_asset_id @request.target_asset_id if @request.target_asset
  xml.state @request.state

  xml.properties {
    @request.request_metadata.attribute_value_pairs.each do |attribute,value|
      xml.property {
        xml.name(attribute.to_field_info.display_name)
        xml.value(value)
      }
    end
  }

  # Events
  xml.events {
    @request.events.each do |event|
      xml.event(id: event.id) {
        xml.message event.message
        xml.content event.content
      }
    end
  } unless @request.events.empty?
  xml.user(@user.login)unless @user.nil?
}
