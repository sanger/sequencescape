
require './lib/request_class_deprecator'
class RemoveCovarisToShearedSpecialization < ActiveRecord::Migration
  include RequestClassDeprecator

  def up
    ActiveRecord::Base.transaction do
      deprecate_class('IlluminaB::Requests::CovarisToSheared')
      deprecate_class('IlluminaHtp::Requests::CovarisToSheared')
    end
  end

  def down
  end
end
