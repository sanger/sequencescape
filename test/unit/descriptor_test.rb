require 'test_helper'

class DescriptorTest < ActiveSupport::TestCase
  context 'A descriptor' do
    should belong_to :task
  end
end
