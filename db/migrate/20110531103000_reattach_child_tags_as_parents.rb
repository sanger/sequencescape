class ReattachChildTagsAsParents < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      TagInstance.find_each do |tag_instance|
        next if tag_instance.parents.empty?

        # Clear the parents and reconnect them as children
        parents = tag_instance.parents.all
        tag_instance.parents.clear
        tag_instance.children = parents
      end
    end
  end

  def self.down
    # There is nothing we can do here to recover the previous state as there are only a partial
    # set of tags that were in this incorrect state.
  end
end
