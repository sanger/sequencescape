module Tasks::MovieLengthHandler # rubocop:todo Style/Documentation
  def render_movie_length_task(task, params)
    @valid_movie_lengths = task.descriptors.find_by(name: 'Movie length').selection
    @default_movie_length = task.descriptors.find_by(name: 'Movie length').value.to_i
    @assets = task.find_batch_requests(params[:batch_id]).map(&:asset).uniq
  end

  def do_movie_length_task(task, params) # rubocop:todo Metrics/MethodLength
    ActiveRecord::Base.transaction do
      params[:asset].each do |asset_id, movie_length|
        asset = Receptacle.find(asset_id)

        unless task.valid_movie_length?(movie_length)
          flash[:error] = 'Invalid movie length'
          return false
        end

        asset.labware.pac_bio_library_tube_metadata.update!(movie_length: movie_length)
      end
    end

    true
  end
end
