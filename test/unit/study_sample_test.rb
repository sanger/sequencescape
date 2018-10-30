require 'test_helper'

class StudySampleTest < ActiveSupport::TestCase
  context 'A StudySample' do
    should belong_to :study
    should belong_to :sample
  end
end
