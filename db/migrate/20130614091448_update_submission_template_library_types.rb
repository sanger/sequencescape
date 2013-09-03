class UpdateSubmissionTemplateLibraryTypes < ActiveRecord::Migration
  def self.templates
    [
      {:name=>'General PCR',     :role=>'PCR',   :type=>'illumina_c_pcr'},
      {:name=>'General no PCR',  :role=>'PCR',   :type=>'illumina_c_nopcr'}
    ]
  end

  def self.up
    ActiveRecord::Base.transaction do
      templates.each do |options|
        IlluminaC::Helper::TemplateConstructor.new(options).update!
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      templates.each do |options|
        IlluminaC::Helper::TemplateConstructor.new(options).update!
      end
    end
  end
end
