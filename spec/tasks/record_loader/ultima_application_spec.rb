# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'record_loader:ultima_application', type: :task do
  # Helper method to load record names from YAML files in a given folder.
  # @return [Array<String>] the unique record names found in the YAML files
  def record_loader_names(folder)
    Rails.root.glob("config/default_records/#{folder}/**/*.yml")
      .flat_map { |path| YAML.load_file(path).keys }
      .uniq
  end

  let(:task) { Rake::Task['record_loader:ultima_application'] }
  let(:expected_primer_names) { record_loader_names('ultima_primers') }
  let(:expected_preset_names) { record_loader_names('ultima_presets') }
  let(:expected_application_names) { record_loader_names('ultima_applications') }
  let(:expected_application_attributes) do
    {
      description: "10x 3' scRNA v4",
      ug100_preset: have_attributes(name: "10x 3' scRNA v4"),
      ug200_preset: have_attributes(name: 'Unprocessed CRAM'),
      uga_primer: have_attributes(name: 'UG-tR1'),
      ugb_primer: have_attributes(name: 'UG-tR2')
    }
  end

  before do
    Rails.application.load_tasks
    %w[ultima_application ultima_primer ultima_preset].each do |task_name|
      Rake::Task["record_loader:#{task_name}"].reenable
    end
  end

  it 'declares the required loader prerequisites' do
    expect(task.prerequisite_tasks.map(&:name)).to include(
      'environment',
      'record_loader:ultima_primer',
      'record_loader:ultima_preset'
    )
  end

  it 'loads primers, presets, and applications' do
    task.invoke

    names = [
      UltimaPrimer.where(name: expected_primer_names).pluck(:name),
      UltimaPreset.where(name: expected_preset_names).pluck(:name),
      UltimaApplication.where(name: expected_application_names).pluck(:name)
    ]
    expect(names).to contain_exactly(expected_primer_names, expected_preset_names, expected_application_names)
  end

  it 'loads application associations' do
    task.invoke
    application = UltimaApplication.find_by!(name: "10x 3' scRNA v4")

    expect(application).to have_attributes(expected_application_attributes)
  end

  it 'is idempotent' do
    task.invoke
    task.reenable

    expect { task.invoke }.not_to change(UltimaApplication, :count)
  end
end
