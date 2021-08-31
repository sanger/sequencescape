# frozen_string_literal: true
class MovieLengthTask < Task # rubocop:todo Style/Documentation
  def partial
    'movie_length_batches'
  end

  def render_task(workflows_controller, params, _user)
    super
    workflows_controller.render_movie_length_task(self, params)
  end

  def do_task(workflows_controller, params, _user)
    workflows_controller.do_movie_length_task(self, params)
  end

  def valid_movie_length?(movie_length)
    return false if movie_length.blank?

    movie_length
      .split(',')
      .each do |movie_timing|
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
