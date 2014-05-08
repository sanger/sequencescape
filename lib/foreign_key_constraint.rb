module ForeignKeyConstraint

  def add_constraint(table,modl,options={})
    parse_options(table,modl,options) do |table,modl,as,fk|
      say "Creating foreign key constraint between #{table}.#{as} and #{modl}.#{fk}"
      connection.execute("ALTER TABLE #{table} ADD CONSTRAINT fk_#{table}_to_#{modl} FOREIGN KEY (#{as}) REFERENCES #{modl} (#{fk});")
    end
  end

  def drop_constraint(table,modl,options={})
    parse_options(table,modl,options) do |table,modl,as,fk|
      say "Dropping foreign key constraint between #{table}.#{as} and #{modl}.#{fk}"
      connection.execute("ALTER TABLE #{table} DROP FOREIGN KEY fk_#{table}_to_#{modl};")
    end
  end

  def parse_options(table,modl,options)
    fk = options[:foreign_key]||'id'
    as = options[:as]||"#{modl.singularize}_id"
    raise 'Invalid table name' unless /\A[a-z_]+\Z/===table
    raise 'Invalid model name' unless /\A[a-z_]+\Z/===modl
    raise 'Invalid foreign key' unless /\A[a-z_]+\Z/===fk
    raise 'Invalid association' unless /\A[a-z_]+\Z/===as
    yield(table,modl,as,fk)
  end

end
