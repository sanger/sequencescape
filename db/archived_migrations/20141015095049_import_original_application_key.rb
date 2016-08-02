#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class ImportOriginalApplicationKey < ActiveRecord::Migration

  class ApiApplication < ActiveRecord::Base
    self.table_name =('api_applications')
  end

  def self.up
    ActiveRecord::Base.transaction do

      return unless configatron.api.authorisation_code.present?
      ApiApplication.create!(
        :name        => 'Default Application',
        :key         => configatron.api.authorisation_code,
        :contact     => configatron.sequencescape_email,
        :description => %Q{Import of the original authorisation code and privileges to maintain compatibility while systems are migrated.},
        :privilege   => 'full'
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ApiApplication.find_by_name('Default Application').destroy
    end
  end
end
