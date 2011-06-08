Factory.define :empty_well, :class => Well do |well|
  well.name                {|a| Factory.next :asset_name }
  well.value               ""
  well.qc_state            ""
  well.resource            nil
  well.barcode             nil
  well.well_attribute      {|wa| wa.association(:well_attribute)}
end

Factory.define :well, :parent => :empty_well do |a|
  # TODO: This should probably set an aliquot but test code (current) relies on it being empty
end

Factory.define :well_attribute do |w|
  w.concentration       23.2
  w.current_volume      15
end

Factory.define :well_with_sample_and_without_plate, :class => Well do |a|
  a.sample { |sample| sample.association(:sample) }
end

Factory.define :well_with_sample_and_plate, :class => Well do |a|
  a.sample { |sample| sample.association(:sample) }
  a.plate  { |plate| plate.association(:plate) }
end
