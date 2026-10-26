# frozen_string_literal: true
class AddTagIdToSampleCompoundsComponents < ActiveRecord::Migration[8.1]
  def change
    comment = 'The tag of the component sample within the compound sample, ' \
              'e.g. for Kinnex. Null when the components are not tagged.'
    add_column :sample_compounds_components, :tag_id, :integer, comment:
  end
end
