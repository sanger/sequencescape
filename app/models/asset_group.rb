class AssetGroup < ActiveRecord::Base

  include Uuid::Uuidable
  include ModelExtensions::AssetGroup

  belongs_to :study
  belongs_to :user
  belongs_to :submission      # Optional, present if created by a particular submission

  has_many :asset_group_assets
  has_many :assets, :through => :asset_group_assets

  validates_presence_of :name, :study
  validates_uniqueness_of :name



  named_scope :for_search_query, lambda { |query| { :conditions => [ 'name LIKE ?', "%#{query}%" ] } }

  def all_samples_have_accession_numbers?
    assets.all? do |asset|
      asset.aliquots.all? { |aliquot| aliquot.sample.accession_number? }
    end
  end

  def self.find_or_create_asset_group(new_assets_name, study)
    # Is new name set or create group
    asset_group = nil
    if ! new_assets_name.empty?
      asset_group = AssetGroup.find(:first,:conditions => [" name = ? ", new_assets_name ])
      if asset_group.nil?
        #create new asset group
        asset_group = AssetGroup.create(:name => new_assets_name, :study => study)
        asset_group.save
      end
    end
    return asset_group
  end

  def duplicate(project)
    # TODO: Implement me
  end

  def move(assets)
    # TODO: Implement me
  end


end
