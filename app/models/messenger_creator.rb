# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

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

    def each_target
      @base.wells.map { |w| yield w }
    end
  end

  belongs_to :purpose
  validates_presence_of :purpose, :root, :template

  validate :template_exists?

  def create!(base)
    finder.new(base).each_target do |target|
      Messenger.create!(target: target, root: root, template: template)
    end
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
