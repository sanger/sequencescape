# frozen_string_literal: true
xml.instruct!
xml.request(api_data) do
  xml.id @request.id
  xml.created_at @request.created_at
  xml.updated_at @request.updated_at
  xml.sample_id @request.samples.first.id if @request.samples.size == 1
  xml.template @request.request_type.name, id: @request.request_type.id if @request.request_type
  xml.read_length(@request.request_metadata.read_length) if @request.request_metadata.read_length.present?
  xml.asset_id @request.asset_id if @request.asset
  xml.target_asset_id @request.target_asset_id if @request.target_asset
  xml.state @request.state

  xml.properties do
    @request.request_metadata.attribute_value_pairs.each do |attribute, value|
      xml.property do
        xml.name(attribute.to_field_info.display_name)
        xml.value(value)
      end
    end
  end

  # Events
  unless @request.events.empty?
    xml.events do
      @request.events.each do |event|
        xml.event(id: event.id) do
          xml.message event.message
          xml.content event.content
        end
      end
    end
  end
  xml.user(@user.login) unless @user.nil?
end
