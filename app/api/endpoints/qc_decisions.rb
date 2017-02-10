# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

class ::Endpoints::QcDecisions < ::Core::Endpoint::Base
  model do
    action(:create) do |request, _|
      request.target.create!(request.attributes.tap do |attributes|
        attributes[:decisions] = (attributes[:decisions] || []).map do |d|
          d.merge('qcable' => Uuid.find_by(external_id: d['qcable']).resource)
        end
      end)
    end
  end

  instance do
    belongs_to(:user, json: 'user')
    belongs_to(:lot, json: 'lot')
    has_many(:qcables, json: 'qcables', to: 'qcables')
  end
end
