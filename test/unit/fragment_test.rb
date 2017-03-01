# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'

class FragmentTest < ActiveSupport::TestCase
  context Fragment do
    context '#to_xml' do
      setup do
        @fragment = create(:fragment)
      end

      should 'not fail if descriptor_fields present' do
        @fragment.add_descriptor(Descriptor.new(name: 'descriptor', value: 'value'))
        @fragment.to_xml.inspect
      end
    end
  end
end
