# frozen_string_literal: true

require './lib/oligo_enumerator'

# Will construct plates with well_count wells filled with samples
class UatActions::GenerateTagGroup < UatActions
  self.title = 'Generate tag group'

  # The description displays on the list of UAT actions to provide additional information
  self.description = 'Generates a tag group of the specified size filled with random oligos.'
  self.category = :auxiliary_data

  # Form fields
  form_field :name,
             :text_field,
             label: 'Tag Group Name',
             help: 'It will not create a tag group with a name that already exists.'
  form_field :size,
             :number_field,
             label: 'Number of Tags',
             help: 'The number of tags that will be generated',
             options: {
               minimum: 1
             }
  form_field :adapter_type_name,
             :select,
             label: 'Adapter Type Name',
             help: 'The name of the adapter type for the tag group.',
             select_options: -> { TagGroup::AdapterType.order(:name).pluck(:name) },
             options: {
               include_blank: 'No Adapter Type'
             }
  form_field :tag_sequence_offset,
             :number_field,
             label: 'Tag Sequence Offset',
             help: 'The offset for tag sequence generation, to allow creation of distinct tag groups. Defaults to 0.',
             options: {
               minimum: 0
             }

  validates :size,
            numericality: {
              less_than_or_equal_to: ->(record) { record.existing_tags },
              message: 'is larger than the tag group with this name which already exists (%{count})'
            },
            if: :existing_tag_group

  #
  # Returns a default copy of the UatAction which will be used to fill in the form
  #
  # @return [UatActions::GenerateTagGroup] A default object for rendering a form
  def self.default
    new(size: 384)
  end

  #
  # [perform description]
  #
  # @return [Boolean] Returns true if the action was successful, false otherwise
  def perform
    # Called by the controller once the form is filled in. Add your actual actions here.
    # All the form fields are accessible as simple attributes.
    # Return true if everything works
    report[:name] = name
    return true if existing_tag_group

    adapter_type = TagGroup::AdapterType.find_by(name: adapter_type_name)

    create_tag_group(name, adapter_type)
  end

  def create_tag_group(name, adapter_type)
    tag_group = TagGroup.create!(name: name, adapter_type_id: adapter_type&.id)

    tag_group.tags.build(
      OligoEnumerator
        .new(size.to_i, tag_sequence_offset.to_i)
        .each_with_index
        .map { |oligo, map_id| { oligo: oligo, map_id: map_id + 1 } }
    )
    tag_group.save
  end

  def existing_tags
    @tag_group.tags.count
  end

  private

  # Any helper methods

  def existing_tag_group
    return @tag_group if defined?(@tag_group)

    @tag_group = TagGroup.find_by(name:)
  end

  #
  # Returns the uat user
  #
  # @return [User] The UAT user can be used in any places where a user is expected.
  def user
    UatActions::StaticRecords.user
  end
end
