# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2014,2015 Genome Research Ltd.

class Endpoints::OrderTemplates < Core::Endpoint::Base
  model do
  end

  instance do
    nested('orders') do
      action(:create) do |request, _|
        ActiveRecord::Base.transaction do
          attributes = ::Io::Order.map_parameters_to_attributes(request.json)
          attributes[:user] = request.user if request.user.present?
          request.target.create_order!(attributes)
        end
      end
    end
  end
end

# Ensure that this template is used for the SubmissionTemplate model whilst it exists.  Without this we
# would need to implement another endpoint and the end users would be confused.
Endpoints::SubmissionTemplates = Endpoints::OrderTemplates
