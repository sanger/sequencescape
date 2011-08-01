class ChangeGenotypingRequestClassToRequest < ActiveRecord::Migration
  def self.update_request_class_to(request_classes)
    request_classes.each do |request_type_name, request_class|
      request_type = RequestType.find_by_name(request_type_name)
      request_type.update_attributes!(:request_class_name => request_class)
      request_type.requests.update_all(%Q{sti_type="#{request_class}"})
    end
  end

  def self.up
    update_request_class_to('Genotyping' => 'GenotypingRequest', 'Cherrypick' => 'Request')
  end

  def self.down
    update_request_class_to('Genotyping' => 'TransferRequest', 'Cherrypick' => 'TransferRequest')
  end
end
