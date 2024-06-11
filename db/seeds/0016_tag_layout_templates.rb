# frozen_string_literal: true

ActiveRecord::Base.transaction do
  # Pulldown
  TagGroup.find_each do |tag_group|
    TagLayoutTemplate.create!(
      name: "#{tag_group.name} in column major order",
      tag_group:,
      direction_algorithm: 'TagLayout::InColumns',
      walking_algorithm: 'TagLayout::WalkWellsByPools'
    )
    TagLayoutTemplate.create!(
      name: "#{tag_group.name} in row major order",
      tag_group:,
      direction_algorithm: 'TagLayout::InRows',
      walking_algorithm: 'TagLayout::WalkWellsByPools'
    )
    TagLayoutTemplate.create!(
      name: "#{tag_group.name} in inverted column major order",
      tag_group:,
      direction_algorithm: 'TagLayout::InInverseColumns',
      walking_algorithm: 'TagLayout::WalkWellsByPools'
    )
    TagLayoutTemplate.create!(
      name: "#{tag_group.name} in inverted row major order",
      tag_group:,
      direction_algorithm: 'TagLayout::InInverseRows',
      walking_algorithm: 'TagLayout::WalkWellsByPools'
    )
  end

  # Pulldown (Illumina A)
  TagLayoutTemplate.create!(
    name: 'Illumina set - 6 mer tags in column major order (first oligo: ATCACG)',
    direction_algorithm: 'TagLayout::InColumns',
    walking_algorithm: 'TagLayout::WalkWellsByPools',
    tag_group: TagGroup.find_by(name: 'Illumina set - 6 mer tags')
  )

  sanger_168_tag_group = TagGroup.find_by(name: 'Sanger_168tags - 10 mer tags')

  # Illumina B
  TagLayoutTemplate.create!(
    name: 'Illumina B tagging',
    direction_algorithm: 'TagLayout::InRows',
    walking_algorithm: 'TagLayout::WalkWellsOfPlate',
    tag_group: sanger_168_tag_group
  )
  TagLayoutTemplate.create!(
    name: 'Illumina B vertical tagging',
    direction_algorithm: 'TagLayout::InColumns',
    walking_algorithm: 'TagLayout::WalkWellsOfPlate',
    tag_group: sanger_168_tag_group
  )

  [
    'Sanger_168tags - 10 mer tags',
    'TruSeq small RNA index tags - 6 mer tags',
    'TruSeq mRNA Adapter Index Sequences'
  ].each do |name|
    next if TagGroup.find_by(name:).nil?

    TagLayoutTemplate.create!(
      name: "Illumina C - #{name}",
      walking_algorithm: 'TagLayout::WalkWellsOfPlate',
      tag_group: TagGroup.find_by(name:),
      direction_algorithm: 'TagLayout::InColumns'
    )
  end
end
