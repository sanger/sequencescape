# Lays out the tags so that they are column ordered.
class TagLayout::InColumns < TagLayout
  def layout_tags_into_wells
    layout_tags_into_wells_by(:column_major_order)
  end
  private :layout_tags_into_wells
end
