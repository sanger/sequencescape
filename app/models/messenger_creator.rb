# frozen_string_literal: true
##
# A messenger creator acts as a message factory for a given
# for a given plate. They are currently triggered by:
# 1. Cherrypick batch release
# They specify both a template (under Api::Messages) and a root
class MessengerCreator < ApplicationRecord
  class SelfFinder
    def initialize(base)
      @base = base
    end

    def each_target
      yield @base
    end
  end

  class WellFinder
    def initialize(base)
      @base = base
    end

    def each_target(&)
      @base.wells.map(&)
    end
  end

  belongs_to :purpose
  validates :purpose, :root, :template, presence: true

  validate :template_exists?

  def create!(base)
    finder.new(base).each_target { |target| Messenger.create!(target:, root:, template:) }
  end

  private

  def template_exists?
    true
  end

  # Returns an appropriate finder class.
  def finder
    "MessengerCreator::#{target_finder_class}".constantize
  rescue NameError
    raise(StandardError, "Unknown finder: #{finder_class_name}")
  end
end
