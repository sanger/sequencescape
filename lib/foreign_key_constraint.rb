#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
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
