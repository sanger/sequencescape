require 'rails_helper'

describe Pooling do

  let(:empty_lb_tube) { create :empty_library_tube }
  let(:untagged_lb_tube1) { create :library_tube }
  let(:untagged_lb_tube2) { create :library_tube }
  let(:tagged_lb_tube1) { create :tagged_library_tube }
  let(:tagged_lb_tube2) { create :tagged_library_tube }
  let(:mx_tube) { create :multiplexed_library_tube }

  it 'should not be valid without source_assets' do
    pooling = Pooling.new(source_assets_ids: [])
    expect(pooling.valid?).to be false
    expect(pooling.errors.full_messages).to include "Source assets can't be blank"
  end

  it 'should not be valid if tubes are not in sqsc, if tubes do not have at least one aliquot or if there is a tag clash' do
    source_assets_ids = [-1, -2, empty_lb_tube.id, untagged_lb_tube1.id, untagged_lb_tube2.id]
    pooling = Pooling.new(source_assets_ids: source_assets_ids)
    expect(pooling.valid?).to be false
    expect(pooling.errors.messages.count).to eq 2
    expect(pooling.errors.full_messages).to include "Source assets with id(s) -1, -2 were not found in sequencescape"
    expect(pooling.errors.full_messages).to include "Source assets with id(s) #{empty_lb_tube.id} do not have any aliquots"
    expect(pooling.errors.full_messages).to include "Tags combinations are not unique"
  end



  context 'execute' do

    before (:each) do
      @source_assets_ids = [tagged_lb_tube1.id, tagged_lb_tube2.id, untagged_lb_tube1.id, mx_tube.id]
      2.times { |n| create(:single_tagged_aliquot, receptacle: mx_tube) }
    end

    it 'should be valid if tubes are in sqsc, have at least 1 aliquot and there is no tag clash' do
      pooling = Pooling.new(source_assets_ids: @source_assets_ids)
      expect(pooling.valid?).to be true
    end

    it 'should create only standard mx tube if stock is not required' do
      pooling = Pooling.new(source_assets_ids: @source_assets_ids)
      pooling.execute
      expect(pooling.stock_mx_tube.present?).to be false
      expect(pooling.standard_mx_tube.aliquots.count).to eq 5
    end

    it 'should create stock and standard mx tube if required' do
      pooling = Pooling.new(source_assets_ids: @source_assets_ids, stock_mx_tube_required: true)
      pooling.execute
      expect(pooling.stock_mx_tube.aliquots.count).to eq 5
      expect(pooling.standard_mx_tube.aliquots.count).to eq 5
    end

  end

end