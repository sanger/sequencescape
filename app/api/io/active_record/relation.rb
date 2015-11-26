#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class ::Io::ActiveRecord::Relation
  extend ::Core::Io::Collection

  class << self
    def as_json(options = {})
      options[:handled_by].generate_json_actions(options[:object], options.merge(:target => options[:response].request.target))
      super
    end

    def size_for(results)
      results.total_entries
    end
    private :size_for
  end
end
