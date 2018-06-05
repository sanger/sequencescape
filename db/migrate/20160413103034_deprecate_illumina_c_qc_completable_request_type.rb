require './lib/request_class_deprecator'

class DeprecateIlluminaCQcCompletableRequestType < ActiveRecord::Migration
  include RequestClassDeprecator

  def up
    ActiveRecord::Base.transaction do
      deprecate_class('IlluminaC::Requests::QcCompleteable')
    end
  end

  def down
  end
end
