class AddDefaultToMovieLength < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Descriptor.find_by_name('Movie length').tap do |ml|
        ml.selection = [30, 60, 90, 120, 180, 210, 240]
        ml.value = 180
      end.save!
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Descriptor.find_by_name('Movie length').tap do |ml|
        ml.selection = [30, 60, 90, 120, 180]
        ml.value = nil
      end.save!
    end
  end
end
