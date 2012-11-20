ActiveRecord::Base.transaction do

  # Pulldown
  TagGroup.find_each do |tag_group|
    TagLayoutTemplate.create!(
      :name                => "#{tag_group.name} in column major order",
      :tag_group           => tag_group,
      :direction_algorithm => 'TagLayout::InColumns',
      :walking_algorithm   => 'TagLayout::WalkWellsByPools'
    )
    TagLayoutTemplate.create!(
      :name                => "#{tag_group.name} in row major order",
      :tag_group           => tag_group,
      :direction_algorithm => 'TagLayout::InRows',
      :walking_algorithm   => 'TagLayout::WalkWellsByPools'
    )
    TagLayoutTemplate.create!(
      :name                => "#{tag_group.name} in inverted column major order",
      :tag_group           => tag_group,
      :direction_algorithm => 'TagLayout::InInverseColumns',
      :walking_algorithm   => 'TagLayout::WalkWellsByPools'
    )
    TagLayoutTemplate.create!(
      :name                => "#{tag_group.name} in inverted row major order",
      :tag_group           => tag_group,
      :direction_algorithm => 'TagLayout::InInverseRows',
      :walking_algorithm   => 'TagLayout::WalkWellsByPools'
    )
  end

  # Illumina B
  tag_group = TagGroup.find_by_name('Sanger_168tags - 10 mer tags')

  TagLayoutTemplate.create!(
    :name => 'Illumina B tagging',
    :direction_algorithm => 'TagLayout::InRows',
    :walking_algorithm => 'TagLayout::WalkWellsOfPlate',
    :tag_group => tag_group
  )
  TagLayoutTemplate.create!(
    :name => 'Illumina B vertical tagging',
    :direction_algorithm => 'TagLayout::InColumns',
    :walking_algorithm => 'TagLayout::WalkWellsOfPlate',
    :tag_group => tag_group
  )

end
