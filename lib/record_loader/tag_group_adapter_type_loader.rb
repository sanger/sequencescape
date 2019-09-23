# frozen_string_literal: true

module RecordLoader
  # Creates the specified adapter types if they are not present
  class TagGroupAdapterTypeLoader < RecordLoader::Base
    self.config_folder = 'tag_group_adapter_types'

    def create!
      ActiveRecord::Base.transaction do
        @config.each do |name, _options|
          TagGroup::AdapterType.find_or_create_by!(name: name)
        end
      end
    end
  end
end
