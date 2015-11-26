#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
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

    ##
    # We make a few assumptions about the layout of the asset rack and its children here.
    # This may need to be revisited in future
    def located_at(locations)
      Well.for_strip_tubes_row(column_wells_for(locations).map do |column,rows|
        [strip_tubes_in_columns[column],column,rows]
      end)
    end

    alias_method :located_at_position, :located_at

    ##
    # Assumes a fixed 12xcolumn-wise strip layout. Will need to delegate and
    # Refactor if things change in future
    def column_wells_for(locations)
      Hash.new {|hash,column| hash[column] = Array.new }. tap do |column_wells|
        Array.wrap(locations).each do |location|
          row, column = /^([A-Z])([0-9]+)$/.match(location).captures
          column_wells[column.to_i-1] << row.getbyte(0)-65
        end
      end
    end

  end

  module AssetRackAssociation
    def self.included(base)
      base.class_eval do
        scope :for_asset_rack, lambda{ |rack| {:select=>'assets.*',:joins=>:container_association,:conditions=>{:container_associations=>{:container_id=>rack.strip_tubes }} }}

        ##
        # Quite specialised scope. Takes array of:
        # [strip_id,strip_colum,row_offset]
        # Strip column is used to provide a quick conversion back to the standard map description
        # This is a performance optimization
        scope :for_strip_tubes_row, lambda{|strips_wells|

          query = 'false'
          conds = [query]
          id_column = Array.new
          strips_wells.each do |strip_id,column_no,rows|
            query << ' OR (fstr_ca.container_id=? AND fstr_map.column_order IN (?))'
            conds.concat([strip_id,rows])
            id_column[column_no] = strip_id
          end

          # Selects a row by performing a simple CHAR conversion on the row order
          # Selects column by finding the index of the strip_tube id in an array based on column
          # Sadly rails doesn't automatically sanitize selects. We're probably safe with this one,
          # but this ensures we can re-use this without worry.
          select = sanitize_sql_array(['assets.*, CONCAT(CHAR(fstr_map.column_order+65),FIELD(fstr_ca.container_id,?)) AS map_description',id_column])
          {
            :select=>select,
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
