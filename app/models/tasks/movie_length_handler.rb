# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2014,2015 Genome Research Ltd.

module Tasks::MovieLengthHandler
  def render_movie_length_task(task, params)
    @valid_movie_lengths = task.descriptors.find_by(name: 'Movie length').selection
    @default_movie_length = task.descriptors.find_by(name: 'Movie length').value.to_i
    @assets = task.find_batch_requests(params[:batch_id]).map { |request| request.asset }.uniq
  end

  def do_movie_length_task(task, params)
    ActiveRecord::Base.transaction do
      params[:asset].each do |asset_id, movie_length|
        asset = Asset.find(asset_id)

        unless task.valid_movie_length?(movie_length)
          flash[:error] = 'Invalid movie length'
          return false
        end

        asset.pac_bio_library_tube_metadata.update_attributes!(movie_length: movie_length)
      end
    end

    true
  end
end
