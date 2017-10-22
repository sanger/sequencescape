# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

module SharedBehaviour::Immutable
  MUTABLE = ['deprecated_at', 'updated_at']

  def self.included(base)
    base.class_eval do
      before_update :save_allowed?
    end
  end

  private

  def save_allowed?
    return true if (changed - MUTABLE).empty?
    raise ActiveRecord::RecordNotSaved, 'This record is immutable. Deprecate it and create a replacement instead.'
  end
end
