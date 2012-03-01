module RequestTypeFactory
  def control_type_name
    key_name.titleize
  end

  def find_control_type
    RequestType.find_by_key(key_name)
  end

  def key_name
    (last_request_type.key || last_request_type.name.gsub(/\s/,'_').downcase) + '_control'
  end

  def last_request_type
    @last_request_type ||= self.request_types.last
  end

  def add_control_request_type
      RequestType.find_or_create_by_key(
        key_name,
        :name               => control_type_name,
        :request_class_name => ControlRequest.to_s,
        :multiples_allowed  => last_request_type.multiples_allowed,
        :initial_state      => last_request_type.initial_state,
        :asset_type         => last_request_type.asset_type,
        :order              => last_request_type.order
      ).tap do |control_request_type|
        self.control_request_type = control_request_type
      end


    # Returning self for chaining...
    self
  end
end
