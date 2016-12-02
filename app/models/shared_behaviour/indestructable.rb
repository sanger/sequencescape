# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

module SharedBehaviour::Indestructable
  def self.included(base)
    base.class_eval do
      before_destroy :prevent_destruction
    end
  end

  private

  def prevent_destruction
    errors.add(:base, 'can not be destroyed and should be deprecated instead!')
    false
  end
end
