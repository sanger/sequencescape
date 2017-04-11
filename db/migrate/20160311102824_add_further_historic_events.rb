class AddFurtherHistoricEvents < ActiveRecord::Migration
  def up
    say 'Adding MX Library complete for ISC'
    mx_library_purpose_id = Purpose.find_by!(name: 'Cap Lib Pool Norm').id

    StateChange.joins(:target).where(target_state: 'passed', assets: { plate_purpose_id: mx_library_purpose_id }).find_each do |sc|
      print ','
      print sc.id
      tube = sc.target
      next if BroadcastEvent::LibraryComplete.find_by(seed_id: tube.id, seed_type: 'Asset').present?
      user = sc.user
      orders = sc.target.requests_as_target.pluck(:order_id).compact.uniq
      orders.each do |order_id|
        BroadcastEvent::LibraryComplete.create!(seed: tube, user: user, properties: { order_id: order_id }, created_at: sc.created_at)
      end
      print '.'
    end

    say 'Adding lib_pcr_xp_created'
    xp_purpose_id = Purpose.find_by!(name: 'Lib PCR-XP').id

    StateChange.joins(:target).where(target_state: 'passed', assets: { plate_purpose_id: xp_purpose_id }).find_each do |sc|
      print ','
      print sc.id
      plate = sc.target
      next if LibraryEvent.find_by(seed_id: plate.id, seed_type: 'Asset').present?
      user = sc.user
      orders = sc.target.requests_as_target.pluck(:order_id).compact.uniq
      orders.each do |_order_id|
        LibraryEvent.create!(seed: plate, user: user, properties: { event_type: 'lib_pcr_xp_created' }, created_at: sc.created_at)
      end
      print '.'
    end
  end

  def down
  end
end
