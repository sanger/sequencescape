class AddMultiplexingSubmissionTemplates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      [
        {:name=>'Multiplex',     :role=>'PCR',      :type=>'illumina_c_multiplexing', :skip_cherrypick => true},
      ].each do |options|
        IlluminaC::Helper::TemplateConstructor.new(options).build!
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      IlluminaC::Helper::TemplateConstructor.find_for('Multiplex').each {|st| st.destroy if st.present? }
    end
  end
end
