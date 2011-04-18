class SetLocationTask < Task

  set_subclass_attribute :acts_on_input, :kind => :bool, :default => false, :display_name => "Set location of input assets if ticked (output otherwise)"
  set_subclass_attribute :location_id, :cast => :int, :default => 4, :kind => :selection, :display_name => "Choose default location", :choices => lambda { Location.all.map{ |l| [l.name, l.id]}}

  def partial
    "set_location"
  end

  def do_task(workflow, params)
    workflow.do_set_location_task(self, params)
  end

  def set_location(asset, location_id)
    asset = Asset.find(asset) unless asset.is_a? Asset
    asset.location_id = location_id
    asset.save
  end
end

