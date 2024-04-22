# frozen_string_literal: true

require 'rails_helper'

describe WorkOrder do
  subject { build(:work_order, work_order_type:) }

  context 'with a work_order_type' do
    let(:work_order_type) { create(:work_order_type) }

    it { is_expected.to be_valid }
  end

  context 'without an work_order_type' do
    let(:work_order_type) { nil }

    it { is_expected.not_to be_valid }
  end

  context 'with requests' do
    let(:requests) { build_list(:request, 2) }
    let(:work_order) { build(:work_order, requests:) }

    describe '#state=' do
      before { work_order.state = 'passed' }

      it 'update the associated requests' do
        requests.each { |request| expect(request.state).to eq('passed') }
      end
    end
  end

  describe WorkOrder::Factory do
    subject(:factory) { described_class.new(submission) }

    let(:submission) { create(:submission, requests:) }
    let(:request_type) { create(:request_type) }

    let(:requests_set_a) { create_list(:request, 3, asset: create(:well), request_type:) }
    let(:requests) { requests_set_a + requests_set_b }

    context 'where request types match' do
      let(:requests_set_b) { create_list(:request, 3, asset: create(:well), request_type:) }

      it { is_expected.to be_valid }

      it 'generates a work_order per asset' do
        work_orders = subject.create_work_orders!
        expect(work_orders).to be_an Array
        expect(work_orders.length).to eq 2
        actual_request_groups = work_orders.map { |wo| wo.requests.to_a }.sort
        expected_request_groups = [requests_set_a.to_a, requests_set_b.to_a].sort
        expect(actual_request_groups).to eq(expected_request_groups)
      end

      it 'sets the work_order_type on each work order' do
        work_orders = subject.create_work_orders!
        work_orders.each { |work_order| expect(work_order.work_order_type.name).to eq(request_type.key) }
      end

      it 'sets the state on each work order' do
        work_orders = subject.create_work_orders!
        expect(work_orders.first.state).to eq('pending')
      end
    end

    context 'where request types clash' do
      let(:requests_set_b) { create_list(:request, 3, asset: create(:well)) }

      it { is_expected.not_to be_valid }
    end
  end
end
