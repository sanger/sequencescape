class CreateRequestsForStudySamples < ActiveRecord::Migration
  def self.up
    # This code can be run anytime and stopped and started
    # It checks the link between a sample -> study_samples -> study and makes sure it can be reached via sample -> asset -> request -> study
    # Be careful if you try to optimize it because some studies have thousands of samples/requests/assets

    Sample.find_each(:include => [:studies]) do |sample|
      sample_studies = sample.studies
      next if sample_studies.empty?

      request_studies = Study.find(:all, :joins => { :requests => :asset }, :conditions => { :requests => { :assets  => { :sample_id => sample.id } } }  )
      unlinked_studies = (sample_studies - request_studies).uniq.select{ |study| ! study.nil? }
      next if unlinked_studies.empty?

      # only need to link 1 asset - since no work has been done on it, its probably a SampleTube or a well on a stock plate, but that doenst really matter.
      asset = Asset.find_by_sample_id(sample.id)

      if asset.nil?
        # Create a sample tube if none exists (for very old samples)
        asset = SampleTube.create!(:sample => sample)
        puts("Created SampleTube for Sample #{sample.id}")
      end

      puts("Linking Sample #{sample.id} to Studies [#{sample_studies.map(&:id).join(',')}]")

      sample_studies.each{ |study| RequestFactory.create_assets_requests([asset.id], study.id) }
    end
  end

  def self.down
  end
end