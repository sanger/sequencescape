class BarcodePrefix < ActiveRecord::Base
  has_many :assets

  acts_as_audited :on => [:destroy, :update]
end
