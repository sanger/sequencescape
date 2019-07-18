# frozen_string_literal: true

require 'test_helper'

class ControlTest < ActiveSupport::TestCase
  context 'A control' do
    should belong_to :pipeline
  end
end
