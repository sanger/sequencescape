Factory.define :well do |a|
  a.name                {|a| Factory.next :asset_name }
  a.value               ""
  a.qc_state            ""
  a.resource            nil
  a.barcode             nil
  a.well_attribute      {|wa| wa.association(:well_attribute)}
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
