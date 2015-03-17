#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class Rename::ChangeName
  include Validateable

  class ChangeNameError < ::StandardError
    attr_reader :object
    def initialize(object)
      @object = object
    end
  end

  InvalidAction = Class.new(ChangeNameError)

  attr_accessor :study
  validates_presence_of(:study)

  attr_accessor :user

  attr_accessor :replace
  validates_presence_of(:replace)
  attr_accessor :with
  validates_presence_of(:with)

  attr_accessor :list_samples_to_rename
  attr_accessor :list_assets_to_rename


  def initialize(attributes)
    attributes.each { |k,v| self.send(:"#{k}=", v) }
  end

  def sample_rename_absent?
    self.list_samples_to_rename.nil? || self.list_samples_to_rename.empty?
  end

  def asset_rename_absent?
    self.list_assets_to_rename.nil? || self.list_assets_to_rename.empty?
  end

  def reload_objects
    self.study.samples.reload
  end

  def execute!
    raise InvalidAction, self unless self.valid?
    perform_rename_action!
  end

private

  def perform_rename_action!
    begin
      ActiveRecord::Base.transaction do
        perform_rename_action_for_sample!  unless sample_rename_absent?
        perform_rename_action_for_asset!  unless asset_rename_absent?
      end
    rescue ActiveRecord::RecordInvalid => exception
      reload_objects
      raise InvalidAction, self
    end
  end

  def perform_rename_action_for_sample!
    samples_to_rename = self.study.samples.with_name(self.list_samples_to_rename)
    samples_to_rename.each { |sample| sample.rename_to!(sample.name.gsub(replace, with)) }
    self.study.comments.create(:description => "Renamed Samples names: " + replace + " to " +  with , :user_id => user.id)
  end

  def perform_rename_action_for_asset!
    asset_to_rename = self.study.assets.with_name(self.list_assets_to_rename)
    asset_to_rename.each do |asset|
      new_name = asset.name.gsub(replace, with)
      asset.update_attributes!(:name => new_name)
    end
    self.study.comments.create(:description => "Renamed Asset names: " + replace + " to " + with, :user_id => user.id)
  end

end
