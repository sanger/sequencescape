# Lays out the tags so that they are row ordered.
class TagLayout::InRows < TagLayout
  def layout_tags_into_wells
    layout_tags_into_wells_by(:row_major_order)
  end
  private :layout_tags_into_wells
end
