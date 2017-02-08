# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class AddHistoricEvents < ActiveRecord::Migration
  def self.up
    say 'Adding Library Start Events'

    start_purpose_id = Purpose.find_by(name: 'Shear').id
    ActiveRecord::Base.transaction do
      StateChange.find_each(joins: :target, conditions: { previous_state: 'pending', target_state: ['started', 'passed'], assets: { plate_purpose_id: start_purpose_id } }) do |sc|
        print ','
        print sc.id
        plate = sc.target
        next if BroadcastEvent::LibraryStart.find_by(seed_id: plate.id, seed_type: 'Asset').present?
        user = sc.user
        orders = Set.new
        sc.target.wells.each do |well|
          next if well.requests_as_target.empty? || well.requests_as_target.first.failed?
          rat = well.requests_as_target.first
          orders << Request::LibraryCreation.where(asset_id: rat.asset_id, submission_id: rat.submission_id).limit(1).pluck(:order_id).first
        end
        orders.each do |order_id|
          BroadcastEvent::LibraryStart.create!(seed: plate, user: user, properties: { order_id: order_id }, created_at: sc.created_at)
        end
        print '.'
      end
    end
    # Strictly speaking we don't need these yet, but it ensures consistency with start events
    # If we made start events Xten only it would be a pain
    say 'Adding MX Library complete'
    mx_library_purpose_id = Purpose.where(name: ['Lib Pool Norm', 'Lib Pool SS-XP-Norm']).map(&:id)

    ActiveRecord::Base.transaction do
      StateChange.find_each(joins: :target, conditions: { target_state: 'passed', assets: { plate_purpose_id: mx_library_purpose_id } }) do |sc|
        print ','
        print sc.id
        tube = sc.target
        next if BroadcastEvent::LibraryComplete.find_by(seed_id: tube.id, seed_type: 'Asset').present?
        user = sc.user
        orders = sc.target.requests_as_target.map(&:order_id).compact.uniq
        orders.each do |order_id|
          BroadcastEvent::LibraryComplete.create!(seed: tube, user: user, properties: { order_id: order_id }, created_at: sc.created_at)
        end
        print '.'
      end
    end

    say 'Adding Plate Library complete'
    plate_library_purpose_id = Purpose.where(name: 'Lib Norm 2')
    ActiveRecord::Base.transaction do
      StateChange.find_each(joins: :target, conditions: { target_state: 'passed', assets: { plate_purpose_id: plate_library_purpose_id } }) do |sc|
        print ','
        print sc.id
        plate = sc.target
        next if BroadcastEvent::PlateLibraryComplete.find_by(seed_id: plate.id, seed_type: 'Asset').present?
        user = sc.user
        orders = Set.new
        sc.target.wells.each do |well|
          next if well.requests_as_target.empty? || well.requests_as_target.first.failed?
          rat = well.requests_as_target.detect { |r| r.is_a?(IlluminaHtp::Requests::LibraryCompletion) }
          orders << rat.order_id
        end
        orders.each do |order_id|
          BroadcastEvent::PlateLibraryComplete.create!(seed: plate, user: user, properties: { order_id: order_id }, created_at: sc.created_at)
        end
        print '.'
      end
    end

    say 'Adding Sequencing'
    pipeline = Pipeline.where(name: ['HiSeq X PE (no controls)', 'HiSeq X PE (spiked in controls)', 'HiSeq X PE (spiked in controls) from strip-tubes'])
    ActiveRecord::Base.transaction do
      SequencingPipeline.find_each do |pipeline|
        pipeline.batches.find_each(conditions: 'state != "pending" OR state != "discarded"') do |batch|
          next if BroadcastEvent::SequencingStart.find_by(seed_id: batch.id, seed_type: 'Batch').present?
          r = batch.requests.first
          next if r.nil?
          re = r.request_events.where(to_state: 'started').order(:id).first
          next if re.nil?
          time = re.current_from
          BroadcastEvent::SequencingStart.create!(seed: batch, user: batch.user, properties: {}, created_at: time)
        end
      end
    end
  end

  def self.down
  end
end
