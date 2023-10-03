# frozen_string_literal: true
module SharedBehaviour::Named
  def self.included(base)
    base.class_eval do
      scope :with_name, ->(*names) { where(name: names.flatten) }
      scope :sorted_by_name, -> { order(:name) }
      scope :alphabetical, -> { order(:name) }
    end
  end
end
