#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class DisableCertainPlatePurposesFromCherrypicking < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    class Relationship < ActiveRecord::Base
      self.table_name =('plate_purpose_relationships')
      belongs_to :parent, :class_name => 'DisableCertainPlatePurposesFromCherrypicking::PlatePurpose'
      belongs_to :child, :class_name => 'DisableCertainPlatePurposesFromCherrypicking::PlatePurpose'
    end

    self.table_name =('plate_purposes')

    has_many :child_relationships, :class_name => 'DisableCertainPlatePurposesFromCherrypicking::PlatePurpose::Relationship', :foreign_key => :parent_id, :dependent => :destroy
    has_many :child_plate_purposes, :through => :child_relationships, :source => :child
  end

  def self.up
    ActiveRecord::Base.transaction do
      # All of the internal plate types for pulldown are not cherrypickable
      [ 'WGS', 'SC', 'ISC' ].each do |pipeline|
        root = PlatePurpose.find_by_name("#{pipeline} stock DNA") or raise StandardError, "Cannot find the #{pipeline} stock DNA plate type"
        plate_purposes = root.child_plate_purposes
        until plate_purposes.empty?
          plate_purpose = plate_purposes.shift
          plate_purpose.update_attributes!(:cherrypickable_target => false)
          plate_purposes.concat(plate_purpose.child_plate_purposes)
        end
      end

      # Disable the legacy plate types that should not be being cherrypicked to
      PlatePurpose.find_by_name("Seqcap WG").tap do |seqcap_wgs|
        raise StandardError, "Cannot find the Seqcap WG plate type" if seqcap_wgs.nil?
        seqcap_wgs.update_attributes!(:cherrypickable_target => false)
      end
    end
  end

  def self.down
    # Do nothing as it's not really relevant
  end
end
