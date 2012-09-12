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
    joins['assets']         = "INNER JOIN assets ON (assets.id=requests.asset_id OR assets.id=requests.target_asset_id)"
    joins['aliquots']       = "INNER JOIN aliquots ON aliquots.receptacle_id=assets.id"
    joins['tags']           = "INNER JOIN tags ON tags.id=aliquots.tag_id"
  end

  # Returns an array of SQL JOINs that need to be made for the given record.  We know that the 
  # entries in JOINS above are in order, so if we can find the index of the model in the keys
  # then the SQL JOINs are all the values to this point.  That is, if you have a Request you
  # need to JOIN the batches table, to the batch_requests, to the requests.
  def joins_for(record)
    index = JOINS.keys.index(record.class.table_name) or return []
    JOINS.values.slice(0, index+1)
  end
  private :joins_for
end
