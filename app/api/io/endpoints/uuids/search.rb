#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class ::Io::Endpoints::Uuids::Search
  def self.model_for_input
    ::Uuids::Search
  end

  def initialize(search)
    @search = search
  end

  def self.json_field_for(attribute)
    attribute
  end
end
