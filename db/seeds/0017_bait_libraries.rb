# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015 Genome Research Ltd.

# Generate a few bait libraries.

unless Rails.env.test?
  { 'Standard' => 'standard', 'Custom - Pipeline' => 'custom', 'Custom - Customer' => 'custom' }.each do |name, category|
    BaitLibraryType.create!(name: name, category: category)
  end

  BaitLibrary::Supplier.create!(name: 'Agilent').tap do |supplier|
    # Standard bait libraries
    supplier.bait_libraries.create!(name: 'Human all exon 50MB', target_species: 'Human',
                                    bait_library_type: BaitLibraryType.first)
    supplier.bait_libraries.create!(name: 'Mouse all exon',      target_species: 'Mouse',
                                    bait_library_type: BaitLibraryType.first)
    supplier.bait_libraries.create!(name: 'Zebrafish ZV9',       target_species: 'Zebrafish',
                                    bait_library_type: BaitLibraryType.first)
    supplier.bait_libraries.create!(name: 'Zebrafish ZV8',       target_species: 'Zebrafish',
                                    bait_library_type: BaitLibraryType.first)
  end
end
