
require 'test_helper'

class FailureTest < ActiveSupport::TestCase
  context 'A failure' do
    should belong_to :failable
  end
end
