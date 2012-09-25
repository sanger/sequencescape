# A cache sweeper that clears out the batch XML that we're caching to improve the performance
# of NPG.
class BatchCacheSweeper < ActiveRecord::Observer
  include XmlCacheHelper

  # All of the following models have some affect on the batch XML that we're caching
  observe Batch, BatchRequest, Request, LibraryTube, MultiplexedLibraryTube, Lane, Aliquot, Tag

  # The controller we're caching
  set_caching_for_controller 'batches'
  set_caching_for_model 'batches'

  # This is an ordered hash, mapping from a model name to the SQL JOIN that needs to be added.
  # It's used to automatically generate the correct query to find the associated batch for a record.
  JOINS = ActiveSupport::OrderedHash.new.tap do |joins|
    joins['batch_requests'] = "INNER JOIN batch_requests ON batch_requests.batch_id=batches.id"
    joins['requests']       = "INNER JOIN requests ON requests.id=batch_requests.request_id"
    joins['aliquots']       = "INNER JOIN aliquots ON (aliquots.receptacle_id=requests.asset_id OR aliquots.receptacle_id=requests.target_asset_id)"
  end

  def through(record, &block)
    model, conditions = case
      when record.is_a?(BatchRequest) then [ 'batch_requests', query_conditions_for(record)                                                ]
      when record.is_a?(Request)      then [ 'batch_requests', "batch_requests.request_id=#{record.id}"                                    ]
      when record.is_a?(Asset)        then [ 'requests',       "(requests.asset_id=#{record.id} OR requests.target_asset_id=#{record.id})" ]
      when record.is_a?(Aliquot)      then [ 'aliquots',       query_conditions_for(record)                                                ]
      when record.is_a?(Tag)          then [ 'aliquots',       "aliquots.tag_id=#{record.id}"                                              ]
    end
    yield(JOINS.values.slice(0, JOINS.keys.index(model)+1), conditions)
  end
  private :through

  def query_details_for(record, &block)
    return yield([], query_conditions_for(record)) if record.is_a?(Batch)
    through(record, &block)
  end
  private :query_details_for
end
