class AddPacBioTransfer < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(
        :key                => 'initial_pacbio_transfer',
        :name               => 'Initial Pacbio Transfer',
        :asset_type         => 'Well',
        :request_class_name => 'PacBioSamplePrepRequest::Initial',
        :order              => 1,
        :target_purpose     => Purpose.find_by_name('PacBio Sheared')
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key('initial_pacbio_transfer').destroy
    end
  end
end
