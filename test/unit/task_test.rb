# frozen_string_literal: true

require 'test_helper'

class TaskTest < ActiveSupport::TestCase
  context 'A Task' do
    should belong_to :workflow
    should have_many :descriptors
  end
end
