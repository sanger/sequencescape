require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', dbfile: ':memory:')

ActiveRecord::Schema.define(version: 1) do
  create_table :posts do |t|
    t.column :name, :string
    t.column :descriptors, :text
    t.column :descriptor_fields, :text
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end

  create_table :active_posts do |t|
    t.column :name, :string
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end

  create_table :descriptors do |t|
    t.column :name, :string
    t.column :value, :string
    t.column :active_post_id, :integer
    t.column :sorter, :integer
    t.column :required, :boolean
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end
end

class Post < ActiveRecord::Base
  acts_as_descriptable
end

class ActivePost < ActiveRecord::Base
  acts_as_descriptable :active
end

class Descriptor < ActiveRecord::Base
  belongs_to :active_post
end
