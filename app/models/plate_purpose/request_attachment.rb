#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
module PlatePurpose::RequestAttachment

  def transition_to(plate, state, contents = nil, customer_accepts_responsibility = false)
    super
    connect_requests(plate, state, contents)
  end

  def connect_requests(plate, state, contents = nil)
    return unless state == connect_on
    wells = plate.wells
    wells = wells.located_at(contents).include_stock_wells unless contents.blank?

    wells.each do |target_well|
      source_wells = target_well.stock_wells
      source_wells.each do |source_well|

        upstream = source_well.requests.detect {|r| r.is_a?(connected_class) }

        # We need to find the downstream requests BEFORE connecting the upstream
        # This is because submission.next_requests tries to take a shortcut through
        # the target_asset if it is defined.
        if connect_downstream
          downstream = upstream.submission.next_requests(upstream)
          downstream.each { |ds| ds.update_attributes!(:asset => target_well) }
        end

        upstream.update_attributes!(:target_asset=> target_well)
        upstream.pass!

        true
      end
    end
  end

  def self.included(base)
    base.class_eval do
      class_inheritable_reader :connect_on
      class_inheritable_reader :connect_downstream
      class_inheritable_reader :connected_class
    end
  end

end
