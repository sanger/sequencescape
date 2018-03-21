# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015 Genome Research Ltd.

class SpecificTubeCreation < TubeCreation
  class ChildPurpose < ApplicationRecord
    self.table_name = 'specific_tube_creation_purposes'
    belongs_to :specific_tube_creation
    belongs_to :tube_purpose, class_name: 'Purpose'
  end

  has_many :creation_child_purposes, class_name: 'SpecificTubeCreation::ChildPurpose'
  has_many :child_purposes, through: :creation_child_purposes, source: :tube_purpose

  validates_presence_of :child_purposes

  # [Array<Hash>] An optional array of hashes which get passed in to the create! action
  #               on tube_purpose.
  #               Allows overriding default attributes, or setting custom
  #               values for. eg. name.
  #               eg. [{ name: 'Tube one' }, { name: 'Tube two' }]
  attr_writer :tube_attributes

  def set_child_purposes=(uuids)
    self.child_purposes = uuids.map { |uuid| Uuid.find_by(external_id: uuid).resource }
  end

  def multiple_purposes
    true
  end

  # If no tube attributes are specified, fall back to an array of empty hashes
  def tube_attributes
    @tube_attributes || Array.new(child_purposes.length, {})
  end

  private

  def no_pooling_expected?
    true
  end

  def create_children!
    self.children = child_purposes.each_with_index.map do |child_purpose, index|
      # For each tube purpose listed in the child_purposes array
      # create a tube via the tube purpose factory, passing in our
      # custom attributes.
      child_purpose.create!(tube_attributes[index])
    end
  end
end
