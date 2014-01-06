class AddMovieLengthDescriptors < ActiveRecord::Migration
  def self.up
    Task.find_by_name('Movie Lengths').descriptors.create!(
      :name => 'Movie length',
      :kind => 'Selection',
      :selection => [30, 60, 90, 120, 180]
    )
  end

  def self.down
    Task.find_by_name('Movie Lengths').descriptors.clear
  end
end
