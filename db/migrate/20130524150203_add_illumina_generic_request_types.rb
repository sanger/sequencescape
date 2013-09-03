class AddIlluminaGenericRequestTypes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaC::Requests.create_request_types
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      IlluminaC::Requests.destroy_request_types
    end
  end
end
