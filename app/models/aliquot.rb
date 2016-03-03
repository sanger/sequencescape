#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.
# An aliquot can be considered to be an amount of a material in a liquid.  The material could be the DNA
# of a sample, or it might be a library (a combination of the DNA sample and a tag).
class Aliquot < ActiveRecord::Base
  include Uuid::Uuidable
  include Api::Messages::FlowcellIO::AliquotExtensions
  include AliquotIndexer::AliquotScopes

  class Receptacle < Asset
    include Transfer::State
    include Aliquot::Remover

    has_many :transfer_requests, :class_name => 'TransferRequest', :foreign_key => :target_asset_id
    has_many :transfer_requests_as_source, :class_name => 'TransferRequest', :foreign_key => :asset_id
    has_many :transfer_requests_as_target, :class_name => 'TransferRequest', :foreign_key => :target_asset_id

    has_many :requests, :inverse_of => :asset, :foreign_key => :asset_id
    has_one  :source_request, ->() { includes(:request_metadata) }, :class_name => "Request", :foreign_key => :target_asset_id
    has_many :requests_as_source, ->() { includes(:request_metadata) }, :class_name => 'Request', :foreign_key => :asset_id
    has_many :requests_as_target, ->() { includes(:request_metadata) }, :class_name => 'Request', :foreign_key => :target_asset_id

    def default_state
      nil
    end

    SAMPLE_PARTIAL = 'assets/samples_partials/asset_samples'

    # A receptacle can hold many aliquots.  For example, a multiplexed library tube will contain more than
    # one aliquot.
    has_many :aliquots, ->() { order(tag_id: :asc, tag2_id: :asc) }, :foreign_key => :receptacle_id, :autosave => true, :dependent => :destroy, :inverse_of => :receptacle
    has_one :primary_aliquot, ->() { order('created_at ASC').readonly }, :class_name => 'Aliquot', :foreign_key => :receptacle_id

    # Our receptacle needs to report its tagging status based on the most highly tagged aliquot. This retrieves it
    has_one :most_tagged_aliquot, ->() { order('tag2_id DESC, tag_id DESC').readonly }, :class_name => 'Aliquot', :foreign_key => :receptacle_id

    # Named scopes for the future
    scope :include_aliquots, -> { includes( :aliquots => [ :sample, :tag, :bait_library ] ) }

    # This is a lambda as otherwise the scope selects Aliquot::Receptacles
    scope :with_aliquots, -> { joins(:aliquots) }

    # Provide some named scopes that will fit with what we've used in the past
    scope :with_sample_id, ->(id)     { where(:aliquots => { :sample_id => Array(id)     }).joins(:aliquots) }
    scope :with_sample,    ->(sample) { where(:aliquots => { :sample_id => Array(sample) }).joins(:aliquots) }

    # TODO: Remove these at some point in the future as they're kind of wrong!
    has_one :sample, :through => :primary_aliquot
    deprecate :sample

    def sample=(sample)
      aliquots.clear
      aliquots << Aliquot.new(:sample => sample)
    end
    deprecate :sample=

    def sample_id
      primary_aliquot.try(:sample_id)
    end
    deprecate :sample_id

    def sample_id=(sample_id)
      aliquots.clear
      aliquots << Aliquot.new(:sample_id => sample_id)
    end
    deprecate :sample_id=

    has_one :get_tag, :through => :primary_aliquot, :source => :tag
    deprecate :get_tag

    def tag
      get_tag.try(:map_id) || ''
    end
    deprecate :tag

    def tags
      aliquots
    end
    deprecate :tags

    def tag_count
      # Find the most highly tagged aliquot
      return 2 if most_tagged_aliquot.tag2_id != Aliquot::UNASSIGNED_TAG
      return 1 if most_tagged_aliquot.tag_id != Aliquot::UNASSIGNED_TAG
      0
    end

    def primary_aliquot_if_unique
      primary_aliquot if aliquots.count == 1
    end

    def type
      self.class.name.underscore
    end

    def specialized_from_manifest=(*args);end
    def library_information;end
    def library_information=(*args);end

    def assign_tag2(tag)
      aliquots.each do |aliquot|
        aliquot.tag2 = tag
        aliquot.save!
      end
    end

    has_many :studies, :through => :aliquots
    has_many :projects, :through => :aliquots
    has_many :samples, :through => :aliquots

    # Contained samples also works on eg. plate
    alias_attribute :contained_samples, :samples
  end

  # Something that is aliquotable can be part of an aliquot.  So sample and tag are both examples.
  module Aliquotable
    def self.included(base)
      base.class_eval do
        extend ClassMethods

        has_many :aliquots
        has_many :receptacles, ->() { distinct },  :through => :aliquots

        def primary_receptacle
          receptacles.order('aliquots.created_at, aliquots.id ASC').first
        end

        has_many :requests, :through => :assets
        has_many :submissions, :through => :requests

      end
    end

    module ClassMethods
      def receptacle_alias(name, options = {}, &block)
        has_many(name, ->() { distinct }, options.merge(:through => :aliquots, :source => :receptacle), &block)
      end
    end
  end

  include Api::AliquotIO::Extensions
  # An aliquot is held within a receptacle
  belongs_to :receptacle, :class_name => 'Asset'

  # An aliquot can belong to a study and a project.
  belongs_to :study
  belongs_to :project

  # An aliquot is an amount of a sample
  belongs_to :sample

  has_one :aliquot_index

  scope :include_summary, -> { includes([:sample, :tag, :tag2]) }
  scope :in_tag_order, -> {
    joins(
      'LEFT OUTER JOIN tags AS tag1s ON tag1s.id = aliquots.tag_id,
       LEFT OUTER JOIN tags AS tag2s ON tag2s.id = aliquots.tag2_id'
    ).order('tag1s.map_id ASC, tag2s.map_id ASC')
  }

  def aliquot_index_value
    aliquot_index.try(:aliquot_index)
  end

  # It may have a tag but not necessarily.  If it does, however, that tag needs to be unique within the receptacle.
  # To ensure that there can only be one untagged aliquot present in a receptacle we use a special value for tag_id,
  # rather than NULL which does not work in MySQL.  It also works because the unassigned tag ID never gets matched
  # for a Tag and so the result is nil!
  UNASSIGNED_TAG = -1
  belongs_to :tag
  before_validation { |record| record.tag_id ||= UNASSIGNED_TAG }

  belongs_to :tag2, :class_name => 'Tag'
  before_validation { |record| record.tag2_id ||= UNASSIGNED_TAG }

  # Might need to remove these if we get a performance hit
  validates_uniqueness_of :tag_id,       :scope => [:receptacle_id, :tag2_id]
  validates_uniqueness_of :tag2_id, :scope => [:receptacle_id, :tag_id]

  def untagged?
    self.tag_id.nil? or self.tag_id == UNASSIGNED_TAG
  end

  def no_tag2?
    self.tag2_id.nil? or self.tag2_id == UNASSIGNED_TAG
  end

  def tagged?
    !self.untagged?
  end

  def tag_with_unassigned_behaviour
    untagged? ? nil : tag_without_unassigned_behaviour
  end
  alias_method_chain(:tag, :unassigned_behaviour)

  # It may have a bait library but not necessarily.
  belongs_to :bait_library

  # An aliquot can represent a library, which is a processed sample that has been fragmented.  In which case it
  # has a receptacle that held the library aliquot and has an insert size describing the fragment positions.
  class InsertSize < Range
    alias_method :from, :first
    alias_method :to,   :last
  end

  # It can belong to a library asset
  belongs_to :library, :class_name => 'Aliquot::Receptacle'
  composed_of :insert_size, :mapping => [%w{insert_size_from from}, %w{insert_size_to to}], :class_name => 'Aliquot::InsertSize', :allow_nil => true

  # Cloning an aliquot should unset the receptacle ID because otherwise it won't get reassigned.  We should
  # also reset the timestamp information as this is a new aliquot really.
  def dup
    super.tap do |cloned_aliquot|
      cloned_aliquot.receptacle_id = nil
      cloned_aliquot.created_at = nil
      cloned_aliquot.updated_at = nil
    end
  end

  def clone
    raise StandardError, "The Behaviour of clone has changed in Rails 3. Please use dup instead!"
  end

  # return all aliquots originated from the current one
  # ie aliquots sharing the sample, tag information, descending the requess graph
  def descendants(include_self=false)
    (include_self ? self : requests).walk_objects({
      Aliquot => :receptacle,
      Receptacle => [:aliquots, :requests_as_source],
      Request => :target_asset
    }) do |object|
      case object
      when Aliquot
        # we cut the walk if the new aliquot doesn't "match" the current one
        object if object =~ self
      else # other objects
        [] # are walked but not returned
      end
    end
  end

  # Aliquot are similar if they share the same sample AND the same tag (if they have one: nil acts as a wildcard))
  def =~(object)
    a, b = [self, object].map { |o| [o.tag_id, o.sample_id, o.tag2_id < 0 ? nil : o.tag2_id ] }
    a.zip(b).all?  { |x, y|  (x || y) == (y || x)  }
  end

  def matches?(object)
    # Note: This function is directional, and assumes that the downstream aliquot
    # is checking the upstream aliquot (or the AliquotRecord)
    case
    when self.sample_id != object.sample_id                                                   then return false # The samples don't match
    when object.library_id.present?      && (self.library_id      != object.library_id)       then return false # Our librarys don't match.
    when object.bait_library_id.present? && (self.bait_library_id != object.bait_library_id)  then return false # We have different bait libraries
    when self.untagged? && object.tagged?                                                     then raise StandardError, "Tag missing from downstream aliquot" # The downstream aliquot is untagged, but is tagged upstream. Something is wrong!
    when object.untagged? && object.no_tag2?                                             then return true # The upstream aliquot was untagged, we don't need to check tags
    else (object.untagged?||(self.tag_id == object.tag_id)) && (object.no_tag2?||(self.tag2_id == object.tag2_id ))  # Both aliquots are tagged, we need to check if they match
    end
  end

  # Unlike the above methods, which allow untagged to match with tagged, this looks for exact matches only
  # only id, timestamps and receptacles are excluded
  def equivalent?(other)
    [:sample_id, :tag_id, :tag2_id, :library_id, :bait_library_id, :insert_size_from, :insert_size_to, :library_type, :project_id, :study_id].all? do |attrib|
      self.send(attrib) == other.send(attrib)
    end
  end

end
