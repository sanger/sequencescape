# frozen_string_literal: true

# Add a validator column to pipelines
class AddValidatorColumnToPipelines < ActiveRecord::Migration[6.1]

  def up
    add_column :pipelines, :validator_class_name, :string
  end

  def down
    remove_column :pipelines, :validator_class_name
  end
end
