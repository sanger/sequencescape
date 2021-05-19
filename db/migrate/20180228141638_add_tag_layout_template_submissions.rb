# frozen_string_literal: true

# In addition to tag2 layouts, we now track tag layouts to allow
# enforcement of unique UDIs. Unlike Tag2 templates though we
# don't want to enforce this all the time, so can toggle our
# uniqueness constraint.
class AddTagLayoutTemplateSubmissions < ActiveRecord::Migration[5.1]
  def change
    create_table :tag_layout_template_submissions do |t|
      t.references :submission, null: false, foreign_key: true, type: :integer
      t.references :tag_layout_template, null: false, foreign_key: true, type: :integer
      t.boolean :enforce_uniqueness
      t.timestamps

      # Allows us to enforce uniqueness when required at the database level
      # This helps avoid race conditions where users try and create two plates
      # with the same template at the same time.
      # When I asked JL how often this would happen, his response was 'pretty much all the time'
      t.index %i[submission_id tag_layout_template_id enforce_uniqueness], name: 'tag_layout_uniqueness', unique: true
    end
  end
end
