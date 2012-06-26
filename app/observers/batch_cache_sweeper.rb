# A cache sweeper that clears out the batch XML that we're caching to improve the performance
# of NPG.
class BatchCacheSweeper < ActiveRecord::Observer
  # All of the following models have some affect on the batch XML that we're caching
  observe Batch, BatchRequest, Request, LibraryTube, MultiplexedLibraryTube, Lane, Aliquot, Tag

  delegate :debug, :to => 'Rails.logger'

  # NOTE: Getting sweepers to work without a controller is not simple!
  #
  # All the documentation suggests that you should be able to simply define the observer methods
  # and then call expire_page with the url_for details.  However, this only works if the sweeper
  # has been paired with a controller, so that the controller is inserted into the sweeper.
  #
  # This is the best way of doing this, hence we simply implement an observer here and then
  # include & delegate everything we need to interact with the cache.
  include ActionController::UrlWriter
  delegate :expire_page, :perform_caching, :to => 'ActionController::Base'
  alias_method(:perform_caching?, :perform_caching)
  private :expire_page, :perform_caching, :perform_caching?
  private :url_for

  # After saving do cleanup of the cache.
  def after_save(record)
    handle(record)
  end

  # Before destroying do clean up of the cache, as after will be too late!
  def before_destroy(record)
    handle(record)
  end

  def handle(record)
    return unless perform_caching?
    debug { "Sweeping batch cache from #{record.class.name}(#{record.id})" }
    batch_ids_for(record).map(&method(:clear_cache))
    debug { "Batch cache sweeping complete for #{record.class.name}(#{record.id})" }
  end
  private :handle

  def clear_cache(id)
    expire_page(url_for(
      :controller => 'batches', :action => 'show', :id => id, :format => :xml,
      :only_path => true, :skip_relative_url_root => true
    ))
  end
  private :clear_cache

  # Finds all of the batches that the specified record relates to
  def batch_ids_for(record)
    joins = joins_for(record)
    query = "SELECT batches.id AS id FROM batches #{joins.join(' ')} WHERE #{record.class.table_name}.id=#{record.id}"
    ActiveRecord::Base.connection.select_all(query).map { |result| result['id'] }
  end
  private :batch_ids_for 

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
