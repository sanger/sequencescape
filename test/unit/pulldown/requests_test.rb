# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

require 'test_helper'

class Pulldown::RequestsTest < ActiveSupport::TestCase
  [:wgs, :sc, :isc].each do |request_type|
    context request_type.to_s.upcase do
      setup do
        @request = create(:"pulldown_#{request_type}_request")
        @request.asset.aliquots.each { |a| a.update_attributes!(project: create(:project)) }
      end
    end
  end
end
