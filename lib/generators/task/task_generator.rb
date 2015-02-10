#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class TaskGenerator < Rails::Generator::NamedBase
  def banner
    "Usage: #{$0} #{spec.name} ModelName"
  end

  def model
    singular_name.classify.constantize
  end

  def manifest
    record do |manifest|
      manifest.directory("app/models/tasks")
      manifest.directory("app/views/workflows")
      manifest.directory("db/migrate")

      manifest.migration_template("migration.rb", "db/migrate", :migration_file_name => "add_#{singular_name}_task")
      manifest.template('handler.rb',      "app/models/tasks/#{singular_name}_handler.rb")
      manifest.template('task.rb',            "app/models/#{singular_name}_task.rb")
      manifest.template('task_view.html.erb', "app/views/workflows/_#{singular_name}_batches.html.erb")



      manifest.readme('WHAT-TO-DO-NEXT')
    end
  end
end
