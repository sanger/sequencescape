ActiveRecord::Base.transaction do
  TagGroup.find_each do |tag_group|
    TagLayoutTemplate.create!(
      :name              => tag_group.name,
      :tag_group         => tag_group,
      :layout_class_name => 'TagLayout::ByPools'
    )

    # Although this is supported by the code, laying out tags in a row major order makes life
    # very difficult when the submissions are laid out in column major order.  It's better to
    # reduce the complexity by not offering this and then limiting the tag templates that can
    # be applied based on the maximum pool size on the plate.
#    TagLayoutTemplate.create!(
#      :name              => "#{tag_group.name} in row major order",
#      :tag_group         => tag_group,
#      :layout_class_name => 'TagLayout::InRows'
#    )
  end
end
