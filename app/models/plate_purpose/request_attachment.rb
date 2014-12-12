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
        upstream.update_attributes!(:target_asset=> target_well)
        upstream.pass!

        return true unless connect_downstream?
        downstream = upstream.submission.next_requests(upstream)
        downstream.each { |ds| ds.update_attributes!(:asset => target_well) }

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
