class AddChromiumSubmissionTemplates < ActiveRecord::Migration
  SEQUENCING_KEYS = %w(
    illumina_c_hiseq_paired_end_sequencing
    illumina_c_single_ended_hi_seq_sequencing
    illumina_c_miseq_sequencing
    illumina_c_hiseq_v4_paired_end_sequencing
    illumina_c_hiseq_v4_single_end_sequencing
    illumina_c_hiseq_2500_paired_end_sequencing
    illumina_c_hiseq_2500_single_end_sequencing
    illumina_c_hiseq_4000_paired_end_sequencing
    illumina_c_hiseq_4000_single_end_sequencing
  )

  def up
    ActiveRecord::Base.transaction do
      IlluminaC::Helper::TemplateConstructor.new(
        name: 'Chromium Library Creation',
        role: 'Chromium',
        type: 'illumina_c_chromium_library',
        sequencing: SEQUENCING_KEYS,
        catalogue: product_catalogue
      ).build!
    end
  end

  def down
    ActiveRecord::Base.transaction do
      IlluminaC::Helper::TemplateConstructor.find_for('Chromium Library Creation', SEQUENCING_KEYS).each { |st| st.destroy }
    end
  end

  def product_catalogue
    @product_catalogue ||= ProductCatalogue.construct!(ProductHelpers.single_template('Chromium'))
  end
end
