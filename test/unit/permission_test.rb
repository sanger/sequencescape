# frozen_string_literal: true

require 'test_helper'

class PermissionTest < ActiveSupport::TestCase
  context 'A property definition' do
    should belong_to :permissable
  end
end
