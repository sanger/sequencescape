class AddChromiumRequestType < ActiveRecord::Migration
  class SubmissionWorkflow < ApplicationRecord
    self.table_name = 'submission_workflows'
  end

  def up
    ActiveRecord::Base.transaction do
      rt = RequestType.create!(
        name: 'Illumina-C Chromium library creation',
        key: 'illumina_c_chromium_library',
        request_class_name: 'IlluminaC::Requests::LibraryRequest', # See class deprecation notice above
        for_multiplexing: true,
        workflow_id: SubmissionWorkflow.find_by(name: 'Next-gen sequencing').id,
        asset_type: 'Well',
        order: 1,
        initial_state: 'pending',
        billable: true,
        product_line: ProductLine.find_by(name: 'Illumina-C'),
        request_purpose: :standard,
        target_purpose: Purpose.find_by(name: 'ILC Lib Pool Norm')
      )
      rt.acceptable_plate_purposes << Purpose.find_by(name: 'ILC Stock')
      rt.library_types = LibraryType.where(name: ['Chromium genome', 'Chromium exome', 'Chromium single cell'])
      RequestType.find_by(key: 'illumina_c_multiplexing').acceptable_plate_purposes << Purpose.find_by!(name: 'ILC Lib Chromium')
      RequestType::Validator.create!(
        request_type: rt,
        request_option: 'library_type',
        valid_options: RequestType::Validator::LibraryTypeValidator.new(rt.id)
      )
    end
  end

  def down
    ActiveRecord::Base.transaction do
      RequestType.find_by(key: 'illumina_c_chromium_library').destroy
    end
  end
end
