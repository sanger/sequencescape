#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
module ViewsSchema

  def self.each_view
    all_views.each do |name|
      definition = ActiveRecord::Base.connection.execute("SHOW CREATE TABLE #{name}").first["Create View"].gsub(/DEFINER=`[^`]*`@`[^`]*` /,'')
      yield(name,definition)
    end
  rescue ActiveRecord::StatementInvalid => exception
      puts %Q{\e[1;31m
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
\e[0m}
      raise exception
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

  def self.update_view(name,definition)
    raise "Invalid name" unless /^[a-z0-9_]*$/===name
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS `#{name}`;")
    create_view(name,definition)
  end
end
