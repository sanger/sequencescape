module Tasks::MovieLengthHandler
  def render_movie_length_task(task, params)
    @assets = task.find_batch_requests(params[:batch_id]).map{ |request| request.asset }.uniq
  end

  def do_movie_length_task(task, params)
    ActiveRecord::Base.transaction do
      params[:asset].each do |asset_id, movie_length|
        asset = Asset.find(asset_id)

        unless task.valid_movie_length?(movie_length)
          flash[:error] = "Invalid movie length"
          return false
        end

        asset.pac_bio_library_tube_metadata.update_attributes!(:movie_length => movie_length)
      end
    end

    true
  end
end