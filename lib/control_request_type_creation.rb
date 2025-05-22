# frozen_string_literal: true
module ControlRequestTypeCreation
  def control_type_name
    key_name.titleize
  end

  def find_control_type
    RequestType.find_by(key: key_name)
  end

  def key_name
    "#{last_request_type.key || last_request_type.name.gsub(/\s/, '_').downcase}_control"
  end

  def last_request_type
    @last_request_type ||= request_types.last
  end

  def add_control_request_type # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    RequestType
      .find_or_create_by(key: key_name) do |crt|
        crt.name = control_type_name
        crt.request_class_name = 'ControlRequest'
        crt.multiples_allowed = last_request_type.multiples_allowed
        crt.initial_state = last_request_type.initial_state
        crt.asset_type = last_request_type.asset_type
        crt.order = last_request_type.order
        crt.request_purpose = :control
      end
      .tap { |control_request_type| self.control_request_type = control_request_type }
    self
  end
end
