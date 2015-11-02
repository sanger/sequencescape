class AddHistoricEvents < ActiveRecord::Migration
  def self.up
    say "Adding Library Start Events"

    start_purpose_id = PlatePurpose.find_by_name('Shear').id
    ActiveRecord::Base.transaction do
      StateChange.find_each(:joins=>:target,:conditions=>{:previous_state=>'pending',:target_state=>['started','passed'],:assets=>{:plate_purpose_id=>start_purpose_id}}) do |sc|
        print sc.id
        plate = sc.target
        user = sc.user
        orders = Set.new
        sc.target.wells.each do |well|
          next if well.requests_as_target.empty? || well.requests_as_target.first.failed?
          rat = well.requests_as_target.first
          orders << Request::LibraryCreation.find(:first,:conditions=>{:asset_id=>rat.asset_id,:submission_id=>rat.submission_id},:select=>'order_id').order_id
        end
        orders.each do |order_id|
          BroadcastEvent::LibraryStart.create!(:seed=>plate,:user=>user,:properties=>{:order_id=>order_id},:created_at=>sc.created_at)
        end
        print '.'
      end
    end
    # Strictly speaking we don't need these yet, but it ensures consistency with start events
    # If we made start events Xten only it would be a pain
    say 'Adding MX Library complete'
    mx_library_purpose_id = PlatePurpose.find_by_name('Lib Norm 2').id

    ActiveRecord::Base.transaction do
      StateChange.find_each(:joins=>:target,:conditions=>{:target_state=>'passed',:assets=>{:plate_purpose_id=>mx_library_purpose_id}}) do |sc|
        print sc.id
        tube = sc.target
        user = sc.user
        orders = target.requests_as_target.map(&:order_id).compact.uniq
        orders.each do |order_id|
          BroadcastEvent::LibraryComplete.create!(:seed=>plate,:user=>user,:properties=>{:order_id=>order_id},:created_at=>sc.created_at)
        end
        print '.'
      end
    end

    say 'Adding Plate Library complete'
    plate_library_purpose_id = PlatePurpose.find_all_ny_name('Lib Norm 2')
    ActiveRecord::Base.transaction do
      StateChange.find_each(:joins=>:target,:conditions=>{:target_state=>'passed',:assets=>{:plate_purpose_id=>mx_library_purpose_id}}) do |sc|
        print sc.id
        plate = sc.target
        user = sc.user
        orders = Set.new
        sc.target.wells.each do |well|
          next if well.requests_as_target.empty? || well.requests_as_target.first.failed?
          rat = well.requests_as_target.detect {|r| r.is_a?(IlluminaHtp::Requests::LibraryCompletion) }
          orders << rat.order_id
        end
        orders.each do |order_id|
          BroadcastEvent::PlateLibraryComplete.create!(:seed=>plate,:user=>user,:properties=>{:order_id=>order_id},:created_at=>sc.created_at)
        end
        print '.'
      end
    end
  end

  def self.down
  end
end
