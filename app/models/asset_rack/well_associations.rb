module AssetRack::WellAssociations

  class WellProxy
    def initialize(rack)
      @asset_rack = rack
      @well_scope = Well.for_asset_rack(rack)
    end

    def method_missing(method,*params,&block)
      @well_scope.send(method,*params,&block)
    end

    def located_at(locations)
      @well_scope
    end
  end

  module AssetRackAssociation
    def self.included(base)
      base.class_eval do
        named_scope :for_asset_rack, lambda{ |rack| {:select=>'assets.*',:joins=>:container_association,:conditions=>{:container_associations=>{:container_id=>rack.strip_tubes }} }}
      end
    end
  end
end
