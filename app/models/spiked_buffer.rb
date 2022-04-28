# frozen_string_literal: true
class SpikedBuffer < LibraryTube # rubocop:todo Style/Documentation
  # The index of a spiked buffer is the first parent library tube.  Note that this does not cover cases where
  # the sti_type is a derivative of LibraryTube, which is actually fine because SpikedBuffer is a LibraryTube
  # and we definitely don't want that in the list.
  # This appears in batch.xml, which gets used by NPG.
  has_one :index_links, # rubocop:todo Rails/HasManyOrHasOneDependent
          lambda {
            joins(:ancestor)
              .where("#{LibraryTube.table_name}": { sti_type: 'LibraryTube' })
              .order("#{LibraryTube.table_name}.id DESC")
              .direct
          },
          class_name: 'AssetLink',
          foreign_key: :descendant_id
  has_one :index, through: :index_links, source: :ancestor

  def name_needs_to_be_generated?
    false
  end
end
