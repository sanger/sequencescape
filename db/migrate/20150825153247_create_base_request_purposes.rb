
class CreateBaseRequestPurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestPurpose.create!(key: 'standard')
      RequestPurpose.create!(key: 'qc')
      RequestPurpose.create!(key: 'internal')
      RequestPurpose.create!(key: 'control')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestPurpose.find_by!(key: 'standard').destroy
      RequestPurpose.find_by!(key: 'qc').destroy
      RequestPurpose.find_by!(key: 'internal').destroy
      RequestPurpose.find_by!(key: 'control').destroy
    end
  end
end
