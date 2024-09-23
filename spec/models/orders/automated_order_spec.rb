# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_order_specs'

RSpec.describe AutomatedOrder do
  subject { build :automated_order, assets: }

  let(:assets) { [tube] }
  let(:tube) { create :multiplexed_library_tube, aliquots: }
  let(:study) { create :study }
  let(:project) { create :project }

  it_behaves_like 'an automated order'

  context 'with a cross study/project tube' do
    let(:aliquots) { create_list :tagged_aliquot, 2 }

    it { is_expected.to be_valid }
  end
end
