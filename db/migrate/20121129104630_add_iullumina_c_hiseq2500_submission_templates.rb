class AddIulluminaCHiseq2500SubmissionTemplates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      each_template do |settings|
        SubmissionTemplate.create!(template(settings))
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_template do |settings|
        SubmissionTemplate.find_by_name(settings[:name]).destroy
      end
    end
  end

  def self.each_template
    [
      {:name => "Illumina-C - Library creation - HiSeq 2500 Paired end sequencing", :library_creation => ['illumina_c_library_creation','library_creation']},
      {:name => "Illumina-C - Multiplexed library creation - HiSeq 2500 Paired end sequencing", :library_creation => ['illumina_c_multiplexed_library_creation']}
    ].each do |settings|
      yield settings
    end
  end

  def self.template(settings)
    {
      :name => settings[:name],
      :submission_parameters => {
        :workflow_id => 1,
        :input_field_infos => [
          FieldInfo.new(:kind => "Text",:default_value => "",:parameters => {},:display_name => "Fragment size required (from)",:key => "fragment_size_required_from"),
          FieldInfo.new(:kind => "Text",:default_value => "",:parameters => {},:display_name => "Fragment size required (to)",:key => "fragment_size_required_to"),
          FieldInfo.new(
            :kind => "Selection",:default_value => "Standard",:parameters => {
              :selection => [
                "NlaIII gene expression","Standard","Long range","Small RNA","DpnII gene expression","qPCR only",
                "High complexity and double size selected","Illumina cDNA protocol","Custom","High complexity",
                "Double size selected","No PCR","Agilent Pulldown","ChiP-seq","Pre-quality controlled","TraDIS"
              ]
            },
            :display_name => "Library type",
            :key => "library_type"
          ),
          FieldInfo.new(:kind => "Selection",:default_value => "100",:parameters => {:selection => ["50","75","100"]},:display_name => "Read length",:key => "read_length")
        ],
        :request_type_ids_list => [[library_request_type(settings).id],[sequencing_request_type.id]],
        :info_differential => 1
      },
      :product_line => ProductLine.find_by_name("Illumina-C"),
      :submission_class_name => "LinearSubmission"
    }
  end

  def self.sequencing_request_type
    RequestType.find_by_key('illumina_c_hiseq_2500_paired_end_sequencing')
  end

  def self.library_request_type(settings)
    # Ugh, our production and seeded database differ
    RequestType.find_by_key(settings[:library_creation].first)||RequestType.find_by_key(settings[:library_creation].last)
  end
end
