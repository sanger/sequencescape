# frozen_string_literal: true
# GPL-528 Add priority to sample to support CGaP Heron automated release
class AddPriorityToSample < ActiveRecord::Migration[5.2]
  def change
    add_column :samples, :priority, :integer, default: 0
  end
end
