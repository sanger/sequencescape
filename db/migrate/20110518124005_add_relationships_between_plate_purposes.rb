class AddRelationshipsBetweenPlatePurposes < ActiveRecord::Migration
  RELATIONSHIPS = {
    "Working Dilution"    => ["Working Dilution", "Pico Dilution"],
    "Pico Dilution"       => ["Working Dilution", "Pico Dilution"],
    "Pico Assay A"        => ["Pico Assay A", "Pico Assay B"],
    "Pulldown"            => ["Pulldown Aliquot"],
    "Dilution Plates"     => ["Working Dilution", "Pico Dilution"],
    "Pico Assay Plates"   => ["Pico Assay A", "Pico Assay B"],
    "Pico Assay B"        => ["Pico Assay A", "Pico Assay B"],
    "Gel Dilution Plates" => ["Gel Dilution"],
    "Pulldown Aliquot"    => ["Sonication"],
    "Sonication"          => ["Run of Robot"],
    "Run of Robot"        => ["EnRichment 1"],
    "EnRichment 1"        => ["EnRichment 2"],
    "EnRichment 2"        => ["EnRichment 3"],
    "EnRichment 3"        => ["EnRichment 4"],
    "EnRichment 4"        => ["Sequence Capture"],
    "Sequence Capture"    => ["Pulldown PCR"],
    "Pulldown PCR"        => ["Pulldown qPCR"]
  }

  def self.up
    ActiveRecord::Base.transaction do
      # All of the PlatePurpose names specified in the keys of RELATIONSHIPS have complicated relationships.
      # The others are simply maps to themselves.
      PlatePurpose.all(:conditions => [ 'name NOT IN (?)', RELATIONSHIPS.keys ]).each do |purpose|
        purpose.child_relationships.create!(:child => purpose)
      end

      # Here are the complicated ones:
      PlatePurpose.all(:conditions => { :name => RELATIONSHIPS.keys }).each do |purpose|
        PlatePurpose.all(:conditions => { :name => RELATIONSHIPS[purpose.name] }).each do |child|
          purpose.child_relationships.create!(:child => child)
        end
      end
    end
  end

  def self.down
    # Nothing needs to be done here really
  end
end
