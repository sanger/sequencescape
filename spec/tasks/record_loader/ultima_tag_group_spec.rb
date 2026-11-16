# frozen_string_literal: true

require 'rails_helper'
require 'rake'

# Loads the records in config/default_records, to check that the existing
# Ultima tag groups get the values their sample sheets had before Ultima
# data was stored (Y26-301), so those sheets don't change.
RSpec.describe 'record_loader:ultima_tag_group', type: :task do
  let(:task) { Rake::Task['record_loader:ultima_tag_group'] }

  let(:p4_name) do
    'UG-RD-1916 (Solaris 2.0 V1 PCR-Free Adapters for Ultima Genomics P4)'
  end
  let(:solaris_p1_name) do
    'UG-RD-1940 (Solaris 2.0 PCR-Free Adapters for Ultima Genomics P1)'
  end

  # Before Y26-301 the sample sheet generator held a plate number and a
  # first Z number per tag group. A tag's Z number was the first Z number
  # plus the tag's position in map_id order, and its well was its map_id
  # in column order on an 8-row plate.
  let(:previous_config) do
    {
      'Ultima P1' => { plate_num: 1, z_start: 1 },
      'Ultima P2' => { plate_num: 2, z_start: 97 },
      'Ultima P3' => { plate_num: 3, z_start: 193 },
      p4_name => { plate_num: 4, z_start: 289 },
      solaris_p1_name => { plate_num: 1, z_start: 1 }
    }
  end

  # [map_id, Z number, well, plate number] of each tag, as the sample sheet
  # generator calculated them before Y26-301.
  def previous_values(tag_group)
    config = previous_config.fetch(tag_group.name)
    tag_group.tags.sort_by(&:map_id).each_with_index.map do |tag, i|
      well = Map::Coordinate.vertical_position_to_description(tag.map_id, 8)
      [tag.map_id, format('Z%04d', config[:z_start] + i), well,
       config[:plate_num]]
    end
  end

  # [map_id, Z number, well, plate number] of each tag, as loaded.
  def loaded_values(tag_group)
    plate_num = tag_group.ultima_tag_group.barcode_plate_num
    tag_group.tags.sort_by(&:map_id).map do |tag|
      [tag.map_id, tag.ultima_tag.index_barcode_num,
       tag.ultima_tag.barcode_plate_well, plate_num]
    end
  end

  def ultima_adapter_tag_groups
    TagGroup.joins(:adapter_type)
      .where(tag_group_adapter_types: { name: 'Ultima' })
  end

  before do
    loaded = Rake::Task.task_defined?('record_loader:ultima_tag_group')
    Rails.application.load_tasks unless loaded
    %w[ultima_tag_group tag_group tag_group_adapter_type].each do |name|
      Rake::Task["record_loader:#{name}"].reenable
    end
  end

  it 'loads the tag groups first' do
    expect(task.prerequisite_tasks.map(&:name))
      .to include('environment', 'record_loader:tag_group')
  end

  it 'gives every tag of every Ultima tag group its Ultima data',
     :aggregate_failures do
    task.invoke
    tags = ultima_adapter_tag_groups.flat_map(&:tags)
    missing = tags.reject(&:ultima_tag).map { |t| [t.tag_group.name, t.map_id] }
    expect(tags).to be_present
    expect(missing).to be_empty
  end

  it 'gives the existing Ultima tag groups the values they had before' do
    task.invoke
    tag_groups = previous_config.keys.map { |name| TagGroup.find_by!(name:) }
    expect(tag_groups.to_h { |tg| [tg.name, loaded_values(tg)] })
      .to eq(tag_groups.to_h { |tg| [tg.name, previous_values(tg)] })
  end

  it 'is idempotent' do
    task.invoke
    task.reenable
    expect { task.invoke }
      .not_to(change { [UltimaTagGroup.count, UltimaTag.count] })
  end
end
