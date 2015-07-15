#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class ::Endpoints::Tag2LayoutTemplates < ::Core::Endpoint::Base
  model do

  end

  instance do
    action(:create) do |request, _|
      ActiveRecord::Base.transaction do
        request.create!(::Io::Tag2Layout.map_parameters_to_attributes(request.json).reverse_merge(:user => request.user))
      end
    end

  end
end
