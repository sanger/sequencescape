#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class MoveSamplesAndTagsForRootedLibraryTubes < ActiveRecord::Migration
  class AssetLink < ActiveRecord::Base
    self.table_name =('asset_links')

    acts_as_dag_links :node_class_name => 'MoveSamplesAndTagsForRootedLibraryTubes::Asset'
  end

  class Aliquot < ActiveRecord::Base
    self.table_name =('aliquots')

    # NOTE: validations are not here as they are DB constraints and we're not UI based
    belongs_to :receptacle, :class_name => 'MoveSamplesAndTagsForRootedLibraryTubes::Asset'
    belongs_to :sample
    belongs_to :tag
  end

  class Request < ActiveRecord::Base
    class Metadata < ActiveRecord::Base
      self.table_name =('request_metadata')
    end

    self.table_name =('requests')

    # More sensible names for the assets
    belongs_to :source_asset, :class_name => 'MoveSamplesAndTagsForRootedLibraryTubes::Asset', :foreign_key => :asset_id
    belongs_to :target_asset, :class_name => 'MoveSamplesAndTagsForRootedLibraryTubes::Asset', :foreign_key => :target_asset_id

    has_one :request_metadata, :class_name => 'MoveSamplesAndTagsForRootedLibraryTubes::Request::Metadata', :foreign_key => :request_id

    LIBRARY_CREATION_REQUEST_TYPES = [ 'LibraryCreationRequest', 'MultiplexedLibraryCreationRequest' ]

    def is_library_creation?
      LIBRARY_CREATION_REQUEST_TYPES.include?(self.sti_type)
    end

    def is_pulldown_library_creation?
      self.sti_type == 'PulldownMultiplexedLibraryCreationRequest'
    end
  end

  class Asset < ActiveRecord::Base
    LIBRARY_TUBES_ONLY = { :conditions => { :sti_type => 'LibraryTube' } }

    # Library tubes also appear to be possible root assets but they are slightly harder to spot than the
    # sample tubes.  We are only looking for those that don't have any parents and have no input requests,
    # and that have no children that are spiked buffers.
    def self.each_root_library_tube(&block)
      total, index = count(LIBRARY_TUBES_ONLY), 0
      find_in_batches(LIBRARY_TUBES_ONLY) do |batch|
        batch.each do |asset|
          yield(asset, index, total) if asset.parents.empty? and asset.requests_as_target.empty? and not asset.children.any?(&:is_spiked_buffer?)
          index += 1
        end
      end
    end

    self.table_name =('assets')

    has_many :requests_as_source, :class_name => 'MoveSamplesAndTagsForRootedLibraryTubes::Request', :foreign_key => :asset_id, :conditions => 'sti_type != "CreateAssetRequest"'
    has_many :requests_as_target, :class_name => 'MoveSamplesAndTagsForRootedLibraryTubes::Request', :foreign_key => :target_asset_id, :conditions => 'sti_type != "CreateAssetRequest"'

    # We're removing these ...
    belongs_to :sample
    has_dag_links :link_class_name => 'MoveSamplesAndTagsForRootedLibraryTubes::AssetLink'
    has_one :tag_instance, :through => :links_as_child, :source => :ancestor, :conditions => { :sti_type => 'TagInstance' }

    # ... and replacing them with these
    has_many :aliquots, :foreign_key => :receptacle_id, :class_name => 'MoveSamplesAndTagsForRootedLibraryTubes::Aliquot' do
      # Returns a list of Aliquot instances that can be attached to another asset.  It also ensures that
      # the aliquots on the asset are maintained correctly.
      def for_attachment
        parent_aliquots = self.map(&:dup)
        if parent_aliquots.empty?
          return [] if proxy_association.owner.sample_id.nil?   # This is an empty receptacle so no point going any further

          aliquot            = Aliquot.new(:sample_id => proxy_association.owner.sample_id)
          aliquot.tag_id     = proxy_association.owner.tag_instance.tag_id if proxy_association.owner.tag_instance.present?
          aliquot.library_id = proxy_association.owner.id if proxy_association.owner.is_library_tube?
          parent_aliquots    = [ aliquot ]

          self << aliquot.dup    # This is our own aliquot too
        elsif parent_aliquots.size == 1 and proxy_association.owner.tag_instance.present?
          if parent_aliquots.first.tag_id.present? and parent_aliquots.first.tag_id != proxy_association.owner.tag_instance.tag_id
            raise StandardError, "Asset #{proxy_association.owner.id} has mismatching tags"
          end

          # Update the tag on our aliquot
          parent_aliquots.first.tag_id = proxy_association.owner.tag_instance.tag_id
          self.first.update_attributes!(:tag_id => proxy_association.owner.tag_instance.tag_id)
        end

        parent_aliquots
      end

      # Attach any of the aliquots that are missing from the specified list.
      def attach_missing_from(aliquots)
        return if aliquots.empty?

        missing_aliquots = aliquots.map(&:dup)
        self.each do |aliquot|
          missing_aliquots.delete_if do |parent_aliquot|
            (parent_aliquot.sample == aliquot.sample) and (parent_aliquot.tag == aliquot.tag)
          end
        end
        self << missing_aliquots unless missing_aliquots.empty?
      end
    end

    # True for any terminal assets, which don't have requests leading out of them.
    def is_terminal?
      self.sti_type == 'Lane'
    end

    def is_library_tube?
      self.sti_type == 'LibraryTube'
    end

    def is_spiked_buffer?
      self.sti_type == 'SpikedBuffer'
    end

    ASSETS_THAT_CAN_HAVE_STOCKS = [ 'LibraryTube', 'MultiplexedLibraryTube' ]

    has_one(:stock_asset, :through => :links_as_child, :source => :ancestor, :conditions => { :sti_type => ASSETS_THAT_CAN_HAVE_STOCKS.map { |n| "Stock#{n}" } })

    def can_have_stock_asset?
      ASSETS_THAT_CAN_HAVE_STOCKS.include?(self.sti_type)
    end

    def has_stock_asset?
      can_have_stock_asset? and stock_asset.present?
    end
  end

  EAGER_LOADING_FOR_ASSETS = { :include => [ :aliquots, :tag_instance, { :requests_as_source => :target_asset } ] }

  def self.walk_from_asset(parent, depth = 0)
    say("#{'-*-'*depth}Walking asset #{parent.id} (#{parent.sti_type})")

    return if parent.is_terminal?   # No point going any further!
    raise StandardError, "Asset #{parent.id} has exceeded the maximum expected depth (do we have a cycle?)" if depth > 10

    # We have to split out the pulldown requests here because they are not to be followed.  However,
    # their library information must be used for the first transfer requests that are followed.
    pulldown_requests, requests_to_follow = parent.requests_as_source.all.partition(&:is_pulldown_library_creation?)
    raise StandardError, "Cannot handle multiple pulldown library creation requests" if pulldown_requests.size > 1
    pulldown_library_request = pulldown_requests.first

    # Copy the aliquots to our children and then process them.  For each request we are
    # copying the aliquot information down, ensuring that we modify it appropriately based on the
    # information in the request.
    parent_aliquots = parent.aliquots.for_attachment
    children        = requests_to_follow.inject([]) do |children, request|
      children.tap do
        next if request.target_asset.nil?

        parent_aliquots_for_request = parent_aliquots.map do |aliquot|
          aliquot.dup.tap do |aliquot_for_child|
            # The study and project are always taken from the request or it's the aliquot's study if the request
            # doesn't have one.
            aliquot_for_child.study_id   = request.study_id   || aliquot_for_child.study_id
            aliquot_for_child.project_id = request.project_id || aliquot_for_child.project_id

            # The library information (the asset that is the library and the insert size) needs to be maintained
            if request.is_library_creation? or pulldown_library_request.present?
              library_request = pulldown_library_request || request

              aliquot_for_child.library_id       = request.target_asset_id  # Target is always from the request
              aliquot_for_child.library_type     = library_request.request_metadata.library_type
              aliquot_for_child.insert_size_from = library_request.request_metadata.fragment_size_required_from
              aliquot_for_child.insert_size_to   = library_request.request_metadata.fragment_size_required_to
            end
          end
        end

        children << request.target_asset.tap do |child|
          child.aliquots.attach_missing_from(parent_aliquots_for_request)
        end
      end
    end

    # If there is a stock asset associated with the current parent then we should treat it like a child, even
    # though, in reality, it's the other way around.
    if parent.has_stock_asset?
      say("#{'-*-'*depth}Dealing with stock asset #{parent.stock_asset.id} (#{parent.stock_asset.sti_type})")
      parent.stock_asset.aliquots.attach_missing_from(parent_aliquots)
    end

    # Now walk to the children
    children.each { |asset| walk_from_asset(asset, depth+1) }
  end

  def self.up
    migration_started = Time.now
    asset_handler = lambda do |asset, index, count|
      begin
        say("Processing #{index+1}/#{count} ...")

        start = Time.now
        walk_from_asset(asset)
        finish = Time.now

        say("Finished #{index+1}/#{count} (%0.03fs, %ds since start)" % [ finish-start, finish-migration_started ])
      rescue => exception
        Rails.logger.error(exception.message)
      end
    end

    ActiveRecord::Base.transaction do
      Asset.each_root_library_tube(&asset_handler)
    end
  end

  def self.down
    # We cannot reverse this migration as it is not possible to (sensibly) work out where the tags
    # and samples came from.  More importantly, once assets start having multiple aliquots it is
    # incredibly hard (and a waste of time) to unwind these.
    raise ActiveRecord::IrreversibleMigration, "There is no way to return from the aliquot model"
  end
end
