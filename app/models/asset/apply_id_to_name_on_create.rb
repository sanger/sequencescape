# frozen_string_literal: true

# Include in classes to add the id onto any name added via #generate_name
# on create.
#
module Asset::ApplyIdToNameOnCreate
  extend ActiveSupport::Concern

  included do
    after_create :generate_name_with_id, if: :name_needs_to_be_generated?
  end

  def generate_name_with_id
    update!(name: "#{name} #{id}")
  end

  def generate_name(new_name)
    self.name = new_name
    @name_needs_to_be_generated = true
  end

  private

  def name_needs_to_be_generated?
    @name_needs_to_be_generated ||= false
  end
end
