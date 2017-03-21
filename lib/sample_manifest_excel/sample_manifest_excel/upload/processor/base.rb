module SampleManifestExcel
  module Upload
    module Processor
      class Base

        include ActiveModel::Model 

        attr_reader :upload
        validates_presence_of :upload
        validate :check_upload_type

        def initialize(upload)
          @upload = upload
        end

        def run(tag_group)
          if valid?
            update_samples(tag_group)
            update_sample_manifest
          end
        end

        def update_samples(tag_group)
          upload.rows.each do |row|
            row.update_sample(tag_group)
          end
        end

        def update_sample_manifest
          upload.sample_manifest.update_attributes(uploaded: File.open(upload.filename))
        end

      private

        def check_upload_type
          unless upload.instance_of?(SampleManifestExcel::Upload::Base)
            errors.add(:base, 'This is no upload fool.')
          end
        end
      end
    end
  end
end
