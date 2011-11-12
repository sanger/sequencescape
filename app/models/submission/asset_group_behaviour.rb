module Submission::AssetGroupBehaviour
  def self.included(base)
    base.class_eval do
      belongs_to    :asset_group
      before_create :find_asset_group,             :unless => :asset_group?
      before_create :pull_assets_from_asset_group, :if     => :asset_group?

      # Required once out of the building state ...
      validates_presence_of :assets, :if => :assets_need_validating?
#      validates_each(:assets, :unless => :building?) do |record, attr, value|
#        record.errors.add(:assets, 'cannot be changed once built') if not record.new_record? and record.assets_was != value
#      end
    end
  end

  # Assets need validating if we are putting this order into a submission and the asset group has not been
  # specified in some form.
  def assets_need_validating?
    not building? and not (asset_group? or not asset_group_name.blank?)
  end
  private :assets_need_validating?

  def complete_building
    create_our_asset_group unless asset_group? or self.assets.blank?
    super
  end

  def asset_group?
    self.asset_group_id.present? or self.asset_group.present?
  end
  private :asset_group?

  def pull_assets_from_asset_group
    self.assets = self.asset_group.assets
  end
  private :pull_assets_from_asset_group

  # NOTE: We cannot name this method 'create_asset_group' because that's provided by 'has_one :asset_group'!
  def create_our_asset_group
    group_name = self.asset_group_name
    group_name = self.uuid if asset_group_name.blank?

    asset_group = self.study.asset_groups.create!(
      :name   => group_name,
      :user   => self.user,
      :assets => self.assets
    )
    self.update_attributes!(:asset_group_id => asset_group.id)
  end
  private :create_our_asset_group

  def find_asset_group
    self.asset_group = self.study.asset_groups.first(:conditions => { :name => asset_group_name }) unless asset_group_name.blank?
  end
  private :find_asset_group
end
