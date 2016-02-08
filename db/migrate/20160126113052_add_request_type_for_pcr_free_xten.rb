class AddRequestTypeForPcrFreeXten < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do |t|
      rt = RequestType.create!(
        :name => 'HTP PCR Free Library',
        :key => 'htp_pcr_free_lib',
        :asset_type => 'Well',
        :deprecated         => false,
        :initial_state      => "pending",
        :for_multiplexing   => true,
        :morphology         => 0,
        :multiples_allowed  => false,
        :no_target_asset    => false,
        :order              => 1,
        :pooling_method     => RequestType::PoolingMethod.find_by_pooling_behaviour!("PlateRow"),
        :request_purpose    => RequestPurpose.find_by_key!("standard"),
        :request_class_name => "IlluminaHtp::Requests::StdLibraryRequest",
        :workflow           => Submission::Workflow.find_by_key!('short_read_sequencing'),
        :product_line       => ProductLine.find_by_name!('Illumina-HTP')
        )

      rt.acceptable_plate_purposes << Purpose.find_by_name!("PF Cherrypicked")

      lt = LibraryType.find_or_create_by_name!("HiSeqX PCR free")
      rt_v = RequestType::Validator.create!(
        :request_type   => rt,
        :request_option => 'library_type',
        :valid_options  => RequestType::Validator::LibraryTypeValidator.new(rt.id)
      )

      RequestType.find_by_key!("htp_pcr_free_lib").library_types << lt
      [
            'htp_pcr_free_lib',
            'illumina_htp_strip_tube_creation',
            'illumina_b_hiseq_x_paired_end_sequencing', "illumina_a_hiseq_x_paired_end_sequencing", "illumina_b_hiseq_x_paired_end_sequencing"].each do |xtlb_name|
        RequestType.find_by_key(xtlb_name).library_types << lt
      end

      st = SubmissionSerializer.construct!({
        :name => "IHTP - PCR Free Auto - HiSeq-X sequencing",
        :submission_class_name => "FlexibleSubmission",
        :product_line => "Illumina-HTP",
        :product_catalogue  => "PFHSqX",
        :submission_parameters => {
          :request_types => [
            'htp_pcr_free_lib',
            'illumina_htp_strip_tube_creation',
            'illumina_b_hiseq_x_paired_end_sequencing'],
          :workflow => "short_read_sequencing"
        }
      })

    end
  end

  def self.down
    ActiveRecord::Base.transaction do |t|
      hiseqlt = LibraryType.find_by_name("HiSeqX PCR free")
      unless hiseqlt.nil?
        ["illumina_a_hiseq_x_paired_end_sequencing", "illumina_b_hiseq_x_paired_end_sequencing"].each do |rt_name|
          rt = RequestType.find_by_key(rt_name)
          lib_types = rt.library_types
          unless lib_types.nil?
            rt.library_types = lib_types.reject{|lt| lt == hiseqlt }
          end
        end
        hiseqlt.destroy
      end
      SubmissionTemplate.find_by_name("IHTP - PCR Free Auto - HiSeq-X sequencing").destroy
      RequestType.find_by_key('htp_pcr_free_lib').destroy
    end
  end
end
