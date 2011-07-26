# Generate a few bait libraries.
BaitLibrary::Supplier.create!(:name => 'Agilent').tap do |supplier|
  supplier.bait_libraries.create!(:name => 'SureSelect Human all exon 50MB', :target_species => 'Human')
  supplier.bait_libraries.create!(:name => 'SureSelect Mouse all exon 50MB', :target_species => 'Mouse')
  supplier.bait_libraries.create!(:name => 'SureSelect Human custom', :target_species => 'Human')
  supplier.bait_libraries.create!(:name => 'SureSelect Mouse custom', :target_species => 'Mouse')
end
