# frozen_string_literal: true
class Event::PlateCreationEvent < Event # rubocop:todo Style/Documentation
  def self.create_for_asset!(asset, plate_purpose, child_plate, user)
    create!(
      eventful: asset,
      message: "Created child #{plate_purpose.name} plate",
      content: Date.today.to_s,
      family: "create_#{plate_purpose.class.name.underscore}",
      created_by: user ? user.login : nil
    )
    create!(
      eventful: child_plate,
      message: "Created #{plate_purpose.name} plate",
      content: Date.today.to_s,
      family: "create_#{plate_purpose.class.name.underscore}",
      created_by: user ? user.login : nil
    )
  end

  def self.create_for_asset_with_date!(asset, plate_purpose, parent_plate, date)
    create!(
      eventful: asset,
      message: "Created #{plate_purpose.name} from #{parent_plate.id}",
      content: date.to_s,
      family: "create_#{plate_purpose.class.name.underscore}"
    )
  end
end
