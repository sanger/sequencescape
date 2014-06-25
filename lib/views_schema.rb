module ViewsSchema

  def self.each_view
    ActiveRecord::Base.connection.execute(%Q{
      SELECT TABLE_NAME AS name
      FROM INFORMATION_SCHEMA.VIEWS
      WHERE TABLE_SCHEMA = '#{ActiveRecord::Base.connection.current_database}';}
    ).each do |view|
      name = view['name']
      definition = ActiveRecord::Base.connection.execute("SHOW CREATE TABLE #{name}").first["Create View"].gsub(/DEFINER=`[^`]*`@`[^`]*` /,'')
      yield(name,definition)
    end
  end

  def self.create_view(name,definition)
    ActiveRecord::Base.connection.execute(definition)
  end
end
