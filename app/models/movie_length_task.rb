# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class MovieLengthTask < Task
  class MovieLengthData < Task::RenderElement
    def initialize(request)
      super(request)
    end
  end

  def create_render_element(request)
    request.asset && MovieLengthData.new(request)
  end

  def partial
    'movie_length_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_movie_length_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_movie_length_task(self, params)
  end

  def valid_movie_length?(movie_length)
    return false if movie_length.blank?
    movie_length.split(/,/).each do |movie_timing|
      return false if (movie_timing.blank? || !movie_timing.to_i.is_a?(Integer) || movie_timing.to_i < 0)
    end

    true
  end

  def included_for_do_task
    [{ requests: :asset }, :pipeline]
  end

  def included_for_render_task
    [{ requests: :asset }, :pipeline]
  end
end
