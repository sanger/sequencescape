class AddRequestTypeForPcrFreeXten < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do |t|
      RequestType.create!(
        :name => 'HTP PCR Free Library',
        :key => 'htp_pcr_free_lib',
        :asset_type => 'Well',
        :deprecated         => false,
        :initial_state      => "pending",
        :for_multiplexing   => false,
        :morphology         => 0,
        :multiples_allowed  => false,
        :no_target_asset    => true,
        :order              => 1,
        :request_purpose    => RequestPurpose.find_by_key("standard"),
        :request_class_name => "HTPLibraryPCRFreeRequest",
        :workflow_id        => Submission::Workflow.find_by_key('short_read_sequencing'),
        :product_line       => ProductLine.find_by_name('Illumina-HTP'),
        ) do | request_type|
        request_type.request_type_validators.build([
          {:request_option=>'insert_size',
          :valid_options=>RequestType::Validator::ArrayWithDefault.new([500,1000,2000,5000,10000,20000],500),
          :request_type=>request_type},
          {:request_option=>'sequencing_type',
          :valid_options=>RequestType::Validator::ArrayWithDefault.new(['Standard','MagBead','MagBead OneCellPerWell v1'],'Standard'),
          :request_type=>request_type}
        ])
      end

      st = SubmissionSerializer.construct!({
        :name => "IHTP - PCR Free Auto - HiSeq-X sequencing",
        :submission_class_name => "LinearSubmission",
        :product_line => "Illumina-HTP",
        :product_catalogue  => "HSqX",
        :submission_parameters => {
          :request_types => [
            'illumina_b_shared',
            'illumina_htp_library_creation',
            'htp_pcr_free_lib',
            'illumina_htp_strip_tube_creation',
            'illumina_b_hiseq_x_paired_end_sequencing'],
          :workflow => "short_read_sequencing"
        }
      })
      lt = LibraryType.find_or_create_by_name!("HiSeqX PCR free")
      rt = RequestType.find_by_key("htp_pcr_free_lib").library_types << lt
      ["illumina_a_hiseq_x_paired_end_sequencing", "illumina_b_hiseq_x_paired_end_sequencing"].each do |xtlb_name|
        RequestType.find_by_key(xtlb_name).library_types << lt
      end
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
    end
  end
end
