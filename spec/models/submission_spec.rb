require 'rails_helper'

RSpec.describe Submission, type: :model do
  def orders_compatible?(a, b, key = nil)
    submission = Submission.new(user: create(:user), orders: [a, b])
    submission.save!
    true
  rescue ActiveRecord::RecordInvalid
    if key
      !submission.errors[key]
    else
      false
    end
  end

  context '#priority' do
    setup do
      @submission = Submission.new(user: create(:user))
    end

    it 'be 0 by default' do
      assert_equal 0, @submission.priority
    end

    it 'be changable' do
      @submission.priority = 3
      assert @submission.valid?
      assert_equal 3, @submission.priority
    end

    it 'have a maximum of 3' do
      @submission.priority = 4
      assert_equal false, @submission.valid?
    end
  end

  context '#orders' do
    let!(:request_type_1) { create(:request_type) }
    let!(:request_type_2) { create(:request_type) }
    let!(:request_type_3) { create(:request_type) }
    let!(:request_type_4) { create(:request_type) }
    let!(:request_type_for_multiplexing) { create(:request_type, for_multiplexing: true) }

    it 'are compatible if all request types after multiplexing requests are the same and all read lengths are the same' do
      request_types = [request_type_1.id, request_type_2.id, request_type_for_multiplexing.id, request_type_3.id, request_type_4.id]
      order1 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order2 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order3 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order4 = create(:order, request_types: [request_type_1.id] + request_types, request_options: { read_length: 100 })
      expect(build(:submission, orders: [order1, order2, order3, order4])).to be_valid
    end

    it 'are compatible if there are no request types for multiplexing' do
      order1 = create(:order, request_types: [request_type_1.id, request_type_2.id], request_options: { read_length: 100 })
      order2 = create(:order, request_types: [request_type_3.id, request_type_1.id, request_type_4.id], request_options: { read_length: 100 })
      order3 = create(:order, request_types: [request_type_1.id], request_options: { read_length: 100 })
      order4 = create(:order, request_types: [request_type_4.id, request_type_3.id], request_options: { read_length: 100 })
      expect(build(:submission, orders: [order1, order2, order3, order4])).to be_valid
    end

    it 'are not compatible with different request types after a multiplexed request types' do
      request_types = [request_type_1.id, request_type_2.id, request_type_for_multiplexing.id, request_type_3.id]
      order1 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order2 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order3 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      request_types[3] = request_type_4.id
      order4 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      expect(build(:submission, orders: [order1, order2, order3, order4])).to_not be_valid
    end

    it 'are not compatible if any of the read lengths are different' do
      request_types = [request_type_1.id, request_type_2.id, request_type_for_multiplexing.id, request_type_3.id]
      order1 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order2 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order3 = create(:order, request_types: request_types, request_options: { read_length: 200 })
      order4 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      expect(build(:submission, orders: [order1, order2, order3, order4])).to_not be_valid
    end

    it 'are not compatible if at least one of the request types are not for multiplexing' do
      request_types = [request_type_1.id, request_type_2.id, request_type_for_multiplexing.id, request_type_3.id]
      order1 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order2 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order3 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      request_types = [request_type_1.id, request_type_2.id, request_type_3.id, request_type_4.id]
      order4 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      expect(build(:submission, orders: [order1, order2, order3, order4])).to_not be_valid
    end
  end

  it 'knows all samples that can not be included in submission' do
    sample_manifest = create :tube_sample_manifest_with_samples
    sample_manifest.samples.first.sample_metadata.update(supplier_name: 'new_name')
    samples = sample_manifest.samples[1..-1]
    order1 = create :order, assets: sample_manifest.labware

    asset = create :empty_sample_tube
    no_manifest_sample = create :sample, assets: [asset]
    order2 = create :order, assets: no_manifest_sample.assets

    submission = Submission.new(user: create(:user), orders: [order1, order2])

    expect(submission.not_ready_samples).to eq samples
  end
end
