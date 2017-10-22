# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011 Genome Research Ltd.
module ExternalResource
  ResourceName = 'SNP'

  def self.included(base)
    base.send(:has_one, :identifier, as: :external)
  end

  def set_identifiable(ident)
    ident.set_external(ResourceName, self)
  end

  alias identifiable= set_identifiable

  def identifiable
    identifier and identifier.identifiable
  end

  def identifiable_id
    identifier and identifier.identifiable.id
  end
end
