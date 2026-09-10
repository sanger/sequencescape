# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UltimaApplication do
  describe 'associations' do
    it { is_expected.to belong_to(:ug100_preset).class_name('UltimaPreset') }
    it { is_expected.to belong_to(:ug200_preset).class_name('UltimaPreset') }
    it { is_expected.to belong_to(:uga_primer).class_name('UltimaPrimer') }
    it { is_expected.to belong_to(:ugb_primer).class_name('UltimaPrimer') }
  end
end
