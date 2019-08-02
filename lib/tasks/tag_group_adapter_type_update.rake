# frozen_string_literal: true

namespace :tag_group do
  namespace :adapter_type do
    desc 'Automatically generate absent adapter types'
    task update: :environment do
      RecordLoader::TagGroupAdapterTypeLoader.new.create!
    end
  end
end
