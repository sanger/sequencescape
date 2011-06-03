class ChangeGenotypingRequestClassToRequest < ActiveRecord::Migration
  def self.update_request_class_to(request_class)
    RequestType.update_all(%Q{request_class_name="#{request_class}"}, 'name="Genotyping"')
  end

  def self.up
    update_request_class_to('Request')
  end

  def self.down
    update_request_class_to('TransferRequest')
  end
end
