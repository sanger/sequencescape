# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

class Endpoints::Submissions < Core::Endpoint::Base
  model do
    action(:create) do |request, _|
      attributes = ::Io::Submission.map_parameters_to_attributes(request.json)
      attributes[:user] = request.user if request.user.present?
      request.target.create!(attributes)
    end
  end

  instance do
    belongs_to(:user, json: 'user')
    has_many(
      :requests, json: 'requests', to: 'requests',
                 include: [:source_asset, :target_asset]
    )

    action(:update, to: :standard_update!, if: :building?)

    bind_action(:create, as: :submit, to: 'submit', if: :building?) do |_, request, response|
      ActiveRecord::Base.transaction do
        request.target.tap do |submission|
          submission.built!
          response.status(200) # OK
        end
      end
    end
  end
end
