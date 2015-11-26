#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class BuildStockWellLinksForAllPulldownPlates < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    self.table_name =('plate_purposes')
    set_inheritance_column

    class Relationship < ActiveRecord::Base
      self.table_name =('plate_purpose_relationships')
      belongs_to :parent, :class_name => 'BuildStockWellLinksForAllPulldownPlates::PlatePurpose'
      belongs_to :child,  :class_name => 'BuildStockWellLinksForAllPulldownPlates::PlatePurpose'
    end

    has_many :parent_relationships, :class_name => 'BuildStockWellLinksForAllPulldownPlates::Purpose::Relationship', :foreign_key => :child_id, :dependent => :destroy
    has_many :parent_purposes, :through => :parent_relationships, :source => :parent
  end

  def self.up
    ActiveRecord::Base.transaction do
      purposes = PlatePurpose.all(:conditions => { :name => Pulldown::PlatePurposes::PLATE_PURPOSE_FLOWS.flatten.uniq })
      raise purposes.map(&:name).inspect if purposes.size != 33
      purposes.each do |purpose|
        stock_well_depth, current_purpose = 0, purpose
        until current_purpose.nil? or current_purpose.can_be_considered_a_stock_plate?
          stock_well_depth += 1
          current_purpose = current_purpose.parent_purposes.first
        end
        raise purpose.name if current_purpose.nil?
        next if stock_well_depth.zero?
        stock_well_depth -= 1

        say_with_time("#{purpose.name}(#{purpose.id}) at depth #{stock_well_depth}") do
          # Build a query that will find all wells that are on plates of this purpose, and mapped to their stock wells.
          joins = (1..stock_well_depth).map do |index|
            "INNER JOIN requests r#{index} ON r#{index-1}.asset_id=r#{index}.target_asset_id AND r#{index}.sti_type IN (#{[TransferRequest, *TransferRequest.descendants].map(&:name).map(&:inspect).join(',')})"
          end

          results = Request.connection.select_all(%Q{
            SELECT 'stock' AS type, r0.target_asset_id AS target_well_id,r#{stock_well_depth}.asset_id AS source_well_id
            FROM assets plates
            INNER JOIN container_associations ON container_associations.container_id=plates.id
            INNER JOIN requests r0 ON r0.target_asset_id=container_associations.content_id AND r0.sti_type IN (#{[TransferRequest, *TransferRequest.descendants].map(&:name).map(&:inspect).join(',')})
            #{joins.join("\n")}
            WHERE plates.plate_purpose_id = #{purpose.id}
          }, "Query for stock wells of #{purpose.name.inspect}")

          # Now generate the links
          results.map(&Well::Link.method(:create!))
        end
      end
    end
  end

  def self.down
    # Do nothing, it's not worth it
  end
end
