# frozen_string_literal: true
module SharedBehaviour::Named # rubocop:todo Style/Documentation
  def self.included(base)
    base.class_eval do
      scope :with_name, ->(*names) { where(name: names.flatten) }
      scope :sorted_by_name, -> { order(:name) }
      scope :alphabetical, -> { order(:name) }
    end
  end
end
