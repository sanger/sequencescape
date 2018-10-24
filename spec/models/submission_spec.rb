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
    sample_manifest.samples.first.sample_metadata.update_attributes(supplier_name: 'new_name')
    samples = sample_manifest.samples[1..-1]
    order1 = create :order, assets: sample_manifest.labware

    asset = create :empty_sample_tube
    no_manifest_sample = create :sample, assets: [asset]
    order2 = create :order, assets: no_manifest_sample.assets

    submission = Submission.new(user: create(:user), orders: [order1, order2])

    expect(submission.not_ready_samples).to eq samples
  end

  # Next requests is used to find downstream requests
  # The current behaviour is explicitly linked to the order in which requests are created
  # so these tests use the submission builder. Please don't switch to building the requests
  # themselves via FactoryBot until the two behaviours are uncoupled
  describe '#next_requests' do
    let(:submission) { create :submission, orders: [order1, order2], state: 'pending' }
    let(:order1) { create(:linear_submission, request_types: order1_request_types, request_options: request_options) }
    let(:order2) { create(:linear_submission, request_types: order2_request_types, request_options: request_options) }
    let(:order1_request1) { submission.requests.detect { |r| r.order == order1 && r.request_type_id == order1_request_types.first } }
    let(:order2_request1) { submission.requests.detect { |r| r.order == order2 && r.request_type_id == order2_request_types.first } }
    let(:request_options) { {} }

    before do
      submission.build_batch
    end

    context 'for a non-multiplexed_submission' do
      let(:order1_request_types) { create_list(:request_type, 3).map(&:id) }
      let(:order2_request_types) { order1_request_types }

      it 'returns a distinct request graph for each request' do
        expect(submission.requests.count).to eq(6)
        order1_request2 = submission.next_requests(order1_request1)
        expect(order1_request2.length).to eq(1)
        order1_request3 = submission.next_requests(order1_request2.first)
        expect(order1_request3.length).to eq(1)
        order2_request2 = submission.next_requests(order2_request1)
        expect(order2_request2.length).to eq(1)
        order2_request3 = submission.next_requests(order2_request2.first)
        expect(order2_request3.length).to eq(1)

        expect(order1_request1).not_to eq(order2_request1)
        expect(order1_request2).not_to eq(order2_request2)
        expect(order1_request2.first.request_type_id).to eq(order1_request_types[1])
        expect(order2_request2.first.request_type_id).to eq(order2_request_types[1])
        expect(order1_request3).not_to eq(order2_request3)
        expect(order1_request3.first.request_type_id).to eq(order1_request_types[2])
        expect(order2_request3.first.request_type_id).to eq(order2_request_types[2])
      end
    end

    context 'for a multiplexed_submission' do
      let(:order1_request_types) { [create(:request_type).id, create(:request_type, for_multiplexing: true).id, create(:request_type).id] }
      let(:order2_request_types) { order1_request_types }

      it 'returns a merging request graph for each request post multiplexing' do
        expect(submission.requests.count).to eq(5)
        order1_request2 = submission.next_requests(order1_request1)
        expect(order1_request2.length).to eq(1)
        order1_request3 = submission.next_requests(order1_request2.first)
        expect(order1_request3.length).to eq(1)
        order2_request2 = submission.next_requests(order2_request1)
        expect(order2_request2.length).to eq(1)
        order2_request3 = submission.next_requests(order2_request2.first)
        expect(order2_request3.length).to eq(1)

        expect(order1_request1).not_to eq(order2_request1)
        expect(order1_request2).not_to eq(order2_request2)
        expect(order1_request2.first.request_type_id).to eq(order1_request_types[1])
        expect(order2_request2.first.request_type_id).to eq(order2_request_types[1])
        expect(order1_request3).to eq(order2_request3)
        expect(order1_request3.first.request_type_id).to eq(order1_request_types[2])
        expect(order2_request3.first.request_type_id).to eq(order2_request_types[2])
      end
    end

    context 'for a multiplexed_submission with a multiplier' do
      let(:post_mx_request_type) { create(:request_type).id }
      let(:order1_request_types) { [create(:request_type).id, create(:request_type, for_multiplexing: true).id, post_mx_request_type] }
      let(:order2_request_types) { order1_request_types }

      let(:request_options) { { multiplier: { post_mx_request_type.to_s => 3 } } }

      it 'returns a merging request graph for each request post multiplexing' do
        expect(submission.requests.count).to eq(7)
        order1_request2 = submission.next_requests(order1_request1)
        expect(order1_request2.length).to eq(1)
        order1_request3 = submission.next_requests(order1_request2.first)
        expect(order1_request3.length).to eq(3)
        order2_request2 = submission.next_requests(order2_request1)
        expect(order2_request2.length).to eq(1)
        order2_request3 = submission.next_requests(order2_request2.first)
        expect(order2_request3.length).to eq(3)

        expect(order1_request1).not_to eq(order2_request1)
        expect(order1_request2).not_to eq(order2_request2)
        expect(order1_request2.first.request_type_id).to eq(order1_request_types[1])
        expect(order2_request2.first.request_type_id).to eq(order2_request_types[1])
        expect(order1_request3).to eq(order2_request3)
        expect(order1_request3.first.request_type_id).to eq(order1_request_types[2])
        expect(order2_request3.first.request_type_id).to eq(order2_request_types[2])
      end
    end

    context 'for a mixed-order multiplexed_submission' do
      let(:post_mx_request_type) { create(:request_type).id }
      let(:mx_request_type) { create(:request_type, for_multiplexing: true).id }
      let(:order1_request_types) { [create(:request_type).id, mx_request_type, post_mx_request_type] }
      let(:order2_request_types) { [create(:request_type).id, mx_request_type, post_mx_request_type] }

      it 'returns a merging request graph for each request post multiplexing' do
        expect(submission.requests.count).to eq(5)
        order1_request2 = submission.next_requests(order1_request1)
        expect(order1_request2.length).to eq(1)
        order1_request3 = submission.next_requests(order1_request2.first)
        expect(order1_request3.length).to eq(1)
        order2_request2 = submission.next_requests(order2_request1)
        expect(order2_request2.length).to eq(1)
        order2_request3 = submission.next_requests(order2_request2.first)
        expect(order2_request3.length).to eq(1)
        expect(order1_request1).not_to eq(order2_request1)
        expect(order1_request2).not_to eq(order2_request2)
        expect(order1_request2.length).to eq(1)
        expect(order1_request2.first.request_type_id).to eq(order1_request_types[1])
        expect(order2_request2.first.request_type_id).to eq(order2_request_types[1])
        expect(order1_request3).to eq(order2_request3)
        expect(order1_request3.length).to eq(1)
        expect(order1_request3.first.request_type_id).to eq(order1_request_types[2])
        expect(order2_request3.first.request_type_id).to eq(order2_request_types[2])
      end
    end
  end
end
