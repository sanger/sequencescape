# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'single_use:fix_fluidigm_acceptable_purposes', type: :task do
  let(:task_name) { 'single_use:fix_fluidigm_acceptable_purposes' }
  let(:task) { Rake::Task[task_name] }
  let(:sta2) { create(:plate_purpose, name: 'STA2') }
  let(:snp_type) { create(:plate_purpose, name: 'SNP Type') }
  let(:snp_type_request) { create(:cherrypick_request_type, key: 'pick_to_snp_type') }
  let(:fluidigm_request) { create(:cherrypick_request_type, key: 'pick_to_fluidigm') }
  let(:expected_output_lines) do
    [
      'Before pick_to_snp_type: ["SNP Type"]',
      'Before pick_to_fluidigm: ["STA2"]',
      'After pick_to_snp_type: ["STA2"]',
      'After pick_to_fluidigm: ["SNP Type"]'
    ]
  end

  before do
    Rake::Task[task_name].clear if Rake::Task.task_defined?(task_name)
    Rake::Task[:environment].clear if Rake::Task.task_defined?(:environment)
    Rake.load_rakefile(Rails.root.join('lib/tasks/single_use/2026_10_fix_fluidigm_acceptable_purposes.rake').to_s)
    Rake::Task.define_task(:environment)
    task.reenable

    snp_type_request.acceptable_purposes << snp_type
    fluidigm_request.acceptable_purposes << sta2
  end

  it 'sets the expected purposes and reports before and after values', :aggregate_failures do
    expect { task.invoke }.to output(include(*expected_output_lines)).to_stdout

    expect(snp_type_request.reload.acceptable_purposes).to contain_exactly(sta2)
    expect(fluidigm_request.reload.acceptable_purposes).to contain_exactly(snp_type)
  end

  it 'aborts before changing either request type if an unexpected purpose is present', :aggregate_failures do
    unexpected_purpose = create(:plate_purpose, name: 'Unexpected purpose')
    fluidigm_request.acceptable_purposes << unexpected_purpose

    expect { task.invoke }.to raise_error(RuntimeError, /Unexpected acceptable purposes/)

    expect(snp_type_request.reload.acceptable_purposes).to contain_exactly(snp_type)
    expect(fluidigm_request.reload.acceptable_purposes).to contain_exactly(sta2, unexpected_purpose)
  end

  it 'is safe to run again after the associations are corrected' do
    task.invoke
    task.reenable

    expect { task.invoke }.not_to(change do
      [
        snp_type_request.reload.acceptable_purposes.pluck(:id),
        fluidigm_request.reload.acceptable_purposes.pluck(:id)
      ]
    end)
  end

  context 'with both purposes on each request type, as in production' do
    def join_row_ids
      RequestType::RequestTypePlatePurpose
        .where(request_type: [snp_type_request, fluidigm_request])
        .ids
    end

    before do
      snp_type_request.acceptable_purposes << sta2
      fluidigm_request.acceptable_purposes << snp_type
    end

    it 'leaves STA2 as the only purpose of Pick to SNP Type' do
      task.invoke
      expect(snp_type_request.reload.acceptable_purposes).to contain_exactly(sta2)
    end

    it 'leaves SNP Type as the only purpose of Pick to Fluidigm' do
      task.invoke
      expect(fluidigm_request.reload.acceptable_purposes).to contain_exactly(snp_type)
    end

    it 'removes only the wrong rows' do
      correct_ids = [
        snp_type_request.request_type_purposes.find_by!(purpose: sta2).id,
        fluidigm_request.request_type_purposes.find_by!(purpose: snp_type).id
      ]
      task.invoke
      expect(join_row_ids).to match_array(correct_ids)
    end
  end
end
