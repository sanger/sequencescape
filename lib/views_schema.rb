# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014 Genome Research Ltd.
module ViewsSchema
  def self.each_view
    all_views.each do |name|
      query = ActiveRecord::Base.connection.execute("SHOW CREATE TABLE #{name}").first
      definition = if query.is_a?(Hash)
                     query['Create View'].gsub(/DEFINER=`[^`]*`@`[^`]*` /, '')
                   elsif query.is_a?(Array)
                     query[1].gsub(/DEFINER=`[^`]*`@`[^`]*` /, '')
                   else
                     raise 'Unknown query format'
                   end
      yield(name, definition)
    end
  rescue ActiveRecord::StatementInvalid => exception
    puts "\e[1;31m
==============================================================
*                          WARNING!                          *
*        The attempt to dump the view schema failed.         *
* It is likely that your migrations have broken one or more  *
*      of the views. It is CRITICAL that this problem is     *
*       addressed before you commit these migrations.        *
*   To ensure that reporting is not affected please ensure   *
*    that the updated view accurately reflects the data.     *
*    DO NOT change the schema of the view, merely how it     *
*   retrieves the data. Ensure the changes are thoroughly    *
*            tested against production like data.            *
*                                                            *
*      Downstream users should be notified of potential      *
*                        disruption.                         *
==============================================================
\e[0m"
    raise exception
  end

  def self.all_views
    ActiveRecord::Base.connection.execute("
      SELECT TABLE_NAME AS name
      FROM INFORMATION_SCHEMA.VIEWS
      WHERE TABLE_SCHEMA = '#{ActiveRecord::Base.connection.current_database}';").map do |v|
      # Behaviour depends on ruby version, so we need to work out what we have
      v.is_a?(Hash) ? v['name'] : v.first
    end.flatten
  end

  def self.create_view(_name, definition)
    ActiveRecord::Base.connection.execute(definition)
  end

  def self.update_view(name, definition)
    drop_view(name)
    create_view(name, definition)
  end

  def self.drop_view(name)
    raise "Invalid name: `#{name}`" unless /^[a-z0-9_]*$/.match?(name)
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS `#{name}`;")
  end
end
