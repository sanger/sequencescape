# frozen_string_literal: true

require 'test_helper'

class QcableLibraryPlatePurposeTest < ActiveSupport::TestCase
  should 'have a QCLibraryPlate state changer' do
    assert_equal QcableLibraryPlatePurpose.state_changer, StateChanger::QcableLibraryPlate
  end
end
