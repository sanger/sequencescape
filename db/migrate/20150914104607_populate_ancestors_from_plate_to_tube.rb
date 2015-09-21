class PopulateAncestorsFromPlateToTube < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ["ILB_STD_MX", "ILC Lib Pool Norm", "Cap Lib Pool Norm", "Legacy MX tube", "Lib Pool Norm", "Lib Pool SS-XP-Norm"].each do |purpose_name|
        purpose = Purpose.find_by_name(purpose_name)
        [Transfer::BetweenSpecificTubes, Transfer::BetweenTubesBySubmission].each do |klass|
          klass.find_each({:conditions =>
            {
              :destinations => {
                :plate_purpose_id => purpose.id
              }
            },
            :joins => [
              "INNER JOIN assets as destinations on destinations.id=destination_id"
              ]
          }) do |t|

            say "Processing #{t.source_id} and #{t.destination_id}"
            source = Asset.find(t.source_id)
            destination = t.destination

            unless AssetLink.edge?(source, destination)
              # As there could be clashes between ancestors while creating the link, we
              # destroy the common for our destination
              (source.ancestors & destination.ancestors).each do |common_ancestor|
                say "Destroying edge between #{common_ancestor.id} and #{destination.id}"
                AssetLink.find_link(common_ancestor, destination).delete if AssetLink.find_link(common_ancestor, destination)
                AssetLink.find_link(common_ancestor, destination).delete if AssetLink.find_link(common_ancestor, destination)
                say "Destroyed edge" unless AssetLink.edge?(common_ancestor, destination)
              end
              source.reload
              destination.reload
              if ((source.ancestors & destination.ancestors).count > 0)
                raise "Still common ancestors...."
              end
              say "Creating edge between #{source.id} and #{destination.id}"
              edge = AssetLink.create_edge!(source, destination)
            end
          end
        end
      end
      say "AssetLink ancestors between tubes created"
    end
  end

  def self.down

  end
end
