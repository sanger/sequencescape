module ViewsSchema

  def self.each_view
    all_views.each do |name|
      definition = ActiveRecord::Base.connection.execute("SHOW CREATE TABLE #{name}").first["Create View"].gsub(/DEFINER=`[^`]*`@`[^`]*` /,'')
      yield(name,definition)
    end
  end

  def self.all_views
    ActiveRecord::Base.connection.execute(%Q{
      SELECT TABLE_NAME AS name
      FROM INFORMATION_SCHEMA.VIEWS
      WHERE TABLE_SCHEMA = '#{ActiveRecord::Base.connection.current_database}';}
    ).map {|v| v['name']}
  end

  def self.create_view(name,definition)
    ActiveRecord::Base.connection.execute(definition)
  end
end
