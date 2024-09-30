# frozen_string_literal: true

require 'test_helper'

class PurposeTest < ActiveSupport::TestCase
  context 'A purpose' do
    setup { @purpose = create(:purpose) }
  end
end
