class ImportOriginalApplicationKey < ActiveRecord::Migration

  class ApiApplication < ActiveRecord::Base
    set_table_name('api_applications')
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
