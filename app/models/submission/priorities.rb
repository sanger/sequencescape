# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

module Submission::Priorities
  def self.priorities
    %w(None Low Medium High)
  end

  def self.options
    (0...priorities.count).map do |i|
      ["#{priorities[i]} - #{i}", i]
    end
  end

  def self.included(base)
    base.class_eval do
      validates_presence_of :priority
      validates_numericality_of :priority, only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 3
    end
  end
end
