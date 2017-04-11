# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2014,2015 Genome Research Ltd.

class ::Endpoints::MultiplexedLibraryTubes < ::Endpoints::LibraryTubes
  instance do
    belongs_to(:custom_metadatum_collection, json: 'custom_metadatum_collection', to: 'custom_metadatum_collection')
    has_many(:requests, json: 'requests', to: 'requests')
    has_many(:qc_files, json: 'qc_files', to: 'qc_files', include: []) do
      action(:create, as: 'create') do |request, _|
        ActiveRecord::Base.transaction do
          QcFile.create!(request.attributes.merge(asset: request.target))
        end
      end
      action(:create_from_file, as: 'create') do |request, _|
        ActiveRecord::Base.transaction do
          request.target.add_qc_file(request.file, request.filename)
        end
      end
    end
  end
end
