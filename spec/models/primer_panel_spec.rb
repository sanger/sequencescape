# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrimerPanel, type: :model do
  let(:primer_panel) { create :primer_panel }

  it 'validates a valid primer panel' do
    expect(primer_panel).to be_valid
  end

  it 'invalidates a primer panel with invalid programs' do
    primer_panel.programs = { 'invalid_label' => {} }
    expect(primer_panel).not_to be_valid
    primer_panel.programs = { 'pcr 1' => { 'invalid_argument' => '' } }
    expect(primer_panel).not_to be_valid
    primer_panel.programs = { 'pcr 1' => { 'duration' => '2min' } }
    expect(primer_panel).not_to be_valid
  end

  it 'invalidates a primer panel with non numerical snp_count' do
    primer_panel.snp_count = 'ABC'
    expect(primer_panel).not_to be_valid
  end

  it 'invalidates a primer panel with wrong minimum snp_count' do
    primer_panel.snp_count = 0
    expect(primer_panel).not_to be_valid
  end

  it 'validates a primer panel with valid programs' do
    primer_panel.programs = { 'pcr 1' => {} }
    expect(primer_panel).to be_valid
    primer_panel.programs = { 'pcr 1' => { 'name' => 'name 1' } }
    expect(primer_panel).to be_valid
    primer_panel.programs = { 'pcr 1' => { 'duration' => '2' } }
    expect(primer_panel).to be_valid
  end

  describe '#summary_hash' do
    it 'returns a summary suitable for exposing in the api' do
      expect(primer_panel.summary_hash).to eq(
        'name' => primer_panel.name,
        'snp_count' => primer_panel.snp_count,
        'programs' => {
          'pcr 1' => {
            'name' => 'pcr1 program',
            'duration' => 45
          },
          'pcr 2' => {
            'name' => 'pcr2 program',
            'duration' => 20
          }
        }
      )
    end
  end
end
