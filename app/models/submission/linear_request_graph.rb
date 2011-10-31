# This module can be included where the submission has a linear behaviour, with no branching.
module Submission::LinearRequestGraph
  # TODO: When Item dies this code will not need to hand it around so much!

  # Builds the entire request graph for this submission.
  def build_request_graph!
    ActiveRecord::Base.transaction do
      create_request_chain!(
        build_request_type_multiplier_pairs,
        assets.map { |asset| [ asset, create_item_for!(asset) ] }
      )
    end
  rescue => exception
    $stderr.puts self.inspect

    $stderr.puts exception.message
    exception.backtrace.map(&$stderr.method(:puts))
    raise
  end

  # Generates a list of RequestType and multiplier pairs for the instance.
  def build_request_type_multiplier_pairs
    # Ensure that the keys of the multipliers hash are strings, otherwise we get weirdness!
    multipliers = Hash.new { |h,k| h[k] = 1 }.tap do |multipliers|
      requested_multipliers = request_options.try(:[], :multiplier) || {}
      requested_multipliers.each { |k,v| multipliers[k.to_s] = v.to_i }
    end

    request_types.dup.map do |request_type_id|
      [ RequestType.find(request_type_id), multipliers[request_type_id.to_s] ]
    end
  end
  private :build_request_type_multiplier_pairs

  def create_target_asset_for!(request_type, source_asset = nil)
    # TODO: What to do when the request type doesn't have an asset?  Returning nil might work!
    return nil if request_type.target_asset_type.blank?
    request_type.target_asset_type.constantize.create! do |asset|
      asset.generate_barcode
      asset.generate_name(source_asset.try(:name) || asset.barcode.to_s)
    end
  end
  private :create_target_asset_for!

  # Creates the next step in the request graph, taking the first request type specified and building
  # enough requests for the source requests.  It will recursively call itself if there are more requests
  # that need creating.
  def create_request_chain!(request_type_and_multiplier_pairs, source_asset_item_pairs)
    raise StandardError, 'No request types specified!' if request_type_and_multiplier_pairs.empty?
    request_type, multiplier = request_type_and_multiplier_pairs.shift

    multiplier.times do |_|
      # If the request type is for multiplexing it means that all of the assets end up in one target asset.
      # Otherwise there are the same number of target assets as source.
      target_assets =
        if request_type.for_multiplexing?
          [ create_target_asset_for!(request_type) ] * assets.size
        else
          source_asset_item_pairs.map { |source_asset, _| create_target_asset_for!(request_type, source_asset) }
        end

      # Now we can iterate over the source assets and target assets building the requests between them.
      # Ensure that the request has the correct comments on it, and that the aliquots of the source asset
      # are transferred into the destination if the request does not do this in some manner itself.
      source_asset_item_pairs.each_with_index do |(source_asset, item), index|
        target_asset = target_assets[index]

        create_request_of_type!(
          request_type,
          :asset => source_asset, :target_asset => target_asset, :item => item
        ).tap do |request|
          # TODO: AssetLink is supposed to disappear at some point in the future because it makes no real sense
          # given that the request graph describes this relationship.
          AssetLink.create_edge!(source_asset, target_asset) if source_asset.present? and target_asset.present?

          comments.each do |comment|
            request.comments.create!(:user => user, :description => comment)
          end if comments.present?
        end
      end

      # Now we can continue to the next request type in the chain, using the target assets we've created.
      # We need to de-duplicate the multiplexed assets.  Note that we duplicate the pairs here so that
      # they don't get disrupted by the shift operation at the start of this method.
      next if request_type_and_multiplier_pairs.empty?
      target_assets =
        if request_type.for_multiplexing?   # May have many nil assets for non-multiplexing
          target_assets.uniq.map { |asset| [ asset, nil ] }  # 'nil' is Item here and should go
        else
          target_assets.each_with_index.map { |asset,index| [ asset || source_asset_item_pairs[index].first, source_asset_item_pairs[index].last ] }
        end
      create_request_chain!(request_type_and_multiplier_pairs.dup, target_assets)
    end
  end
  private :create_request_chain!

  # TODO: Remove this it's not supposed to be being used!
  def create_item_for!(asset)
    item = nil
    item = asset.requests.first.item unless asset.requests.empty?
    return item if item.present?

    Item.create!(:workflow => workflow, :name => "#{asset.display_name} #{id.to_s}", :submission => self.submission)
  end
  private :create_item_for!
end
