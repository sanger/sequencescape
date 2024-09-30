# frozen_string_literal: true

# Generate a few bait libraries.

{ 'Standard' => 'standard', 'Custom - Pipeline' => 'custom', 'Custom - Customer' => 'custom' }.each do |name, category|
  BaitLibraryType.create!(name:, category:)
end

BaitLibrary::Supplier
  .create!(name: 'Agilent')
  .tap do |supplier|
    # Standard bait libraries
    supplier.bait_libraries.create!(
      name: 'Human all exon 50MB',
      target_species: 'Human',
      bait_library_type: BaitLibraryType.first
    )
    supplier.bait_libraries.create!(
      name: 'Mouse all exon',
      target_species: 'Mouse',
      bait_library_type: BaitLibraryType.first
    )
    supplier.bait_libraries.create!(
      name: 'Zebrafish ZV9',
      target_species: 'Zebrafish',
      bait_library_type: BaitLibraryType.first
    )
    supplier.bait_libraries.create!(
      name: 'Zebrafish ZV8',
      target_species: 'Zebrafish',
      bait_library_type: BaitLibraryType.first
    )
  end
