class ChangeControlRequests < ActiveRecord::Migration
  # Control requests have to be a specific type but to get them we have to work from all control assets.
  # To ensure that the correct requests are changed we make sure that the previous class name is given
  # to limit the updates.
  def self.change_request_class_to(previous_class_name, new_class_name)
    ActiveRecord::Base.transaction do
      Asset.find_each(:conditions => { :resource => true }) do |control_asset|
        control_asset.requests_as_source.update_all(%Q{sti_type="#{new_class_name}"}, [ 'sti_type=?', previous_class_name ])
      end
    end
  end

  def self.up
    change_request_class_to('Request', 'ControlRequest')
  end

  def self.down
    change_request_class_to('ControlRequest', 'Request')
  end
end
