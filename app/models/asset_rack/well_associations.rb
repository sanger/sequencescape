module AssetRack::WellAssociations

  class WellProxy

    attr_reader :asset_rack

    def initialize(rack)
      @asset_rack = rack
    end

    def well_scope
      Well.for_asset_rack(asset_rack)
    end

    def method_missing(method,*params,&block)
      well_scope.send(method,*params,&block)
    end

    def strip_tubes_in_columns
      @stic ||= Hash[asset_rack.strip_tubes.map {|st| [st.map.column, st.id] }]
    end

    # ##
    # # Currently this only supports column-based strip tubes
    # # Its also a bit messier than I'd like.
    # def located_at(locations)
    #   column_wells = Hash.new {|hash,column| hash[column] = Array.new }

    #   asset_rack.maps.where_description(locations).each do |m|
    #     column_wells[m.column] << m.row
    #   end

    #   Well.for_strip_tubes_row(column_wells.map do |column,rows|
    #     [strip_tubes_in_columns[column],rows]
    #   end)
    # end

    ##
    #
    def located_at(locations)
      Well.for_strip_tubes_row(column_wells_for(locations).map do |column,rows|
        [strip_tubes_in_columns[column],rows]
      end)
    end

    ##
    # Assumes a fixed 12xcolumn-wise strip layout. Will need to delegate and
    # Refactor if things change in future
    def column_wells_for(locations)
      Hash.new {|hash,column| hash[column] = Array.new }. tap do |column_wells|
        locations.each do |location|
          row, column = /^([A-Z])([0-9]+)$/.match(location).captures
          column_wells[column.to_i-1] = row[0]-65
        end
      end
    end

  end

  module AssetRackAssociation
    def self.included(base)
      base.class_eval do
        named_scope :for_asset_rack, lambda{ |rack| {:select=>'assets.*',:joins=>:container_association,:conditions=>{:container_associations=>{:container_id=>rack.strip_tubes }} }}

        named_scope :for_strip_tubes_row, lambda{|strips_wells|
          query = 'false'
          conds = [query]
          strips_wells.each do |strip_id,rows|
            query << ' OR (fstr_ca.container_id=? AND fstr_map.row_order IN (?))'
            conds.concat([strip_id,rows])
          end
          {
            :select=>'assets.*',
            :joins=>[
              'INNER JOIN container_associations AS fstr_ca ON fstr_ca.content_id = assets.id',
              'INNER JOIN maps AS fstr_map ON fstr_map.id = assets.map_id'
            ],
            :conditions=>conds
          }
        }
      end
    end
  end
end
