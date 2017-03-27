module SampleManifestExcel
  module Upload
    module Processor

      ##
      # Uploads will be processed slightly differently based on the manifest type.
      # Currently only supports tubes.
      class Base
        include ActiveModel::Model
        include SubclassChecker

        has_subclasses :one_d_tube, :multiplexed_library_tube, modual: to_s.deconstantize

        attr_reader :upload
        validates_presence_of :upload
        validate :check_upload_type

        def initialize(upload)
          @upload = upload
        end

        ##
        # If the processor is valid the samples and manifest are updated.
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

        def samples_updated?
          upload.rows.all? { |row| row.sample_updated? }
        end

        def processed?
          @processed ||= samples_updated? && sample_manifest_updated?
        end

        ##
        # Override the sample manifest with the raw uploaded data.
        def update_sample_manifest
          @sample_manifest_updated = upload.sample_manifest.update_attributes(uploaded: File.open(upload.filename))
        end

        def sample_manifest_updated?
          @sample_manifest_updated
        end

        def type
          self.class.to_s
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
