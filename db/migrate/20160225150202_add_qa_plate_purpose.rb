class AddQaPlatePurpose < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do |_t|
      qa_plate_purpose = PlatePurpose.create!(name: "QA Plate")
      Purpose::Relationship.create(parent: PlatePurpose.find_by_name("QA Plate"), child: PlatePurpose.find_by_name("Tag PCR"), transfer_request_type: RequestType.find_by_key('transfer'))
    end
  end

  def down
  end
end
