class Location < ActiveRecord::Base
  has_many :pipelines
  #has_many :assets, :as => :holder

  def set_locations(assets)
    assets.each do |asset|
      asset.location = self
      asset.save
    end
  end
end
