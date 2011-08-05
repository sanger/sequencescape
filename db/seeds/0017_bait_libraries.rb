# Generate a few bait libraries.
BaitLibrary::Supplier.create!(:name => 'Agilent').tap do |supplier|
  # Standard bait libraries
  supplier.bait_libraries.create!(:name => 'Human all exon 50MB', :target_species => 'Human')
  supplier.bait_libraries.create!(:name => 'Mouse all exon',      :target_species => 'Mouse')
  supplier.bait_libraries.create!(:name => 'Zebrafish ZV9',       :target_species => 'Zebrafish')
  supplier.bait_libraries.create!(:name => 'Zebrafish ZV8',       :target_species => 'Zebrafish')
end
