require 'rdoc/task'

namespace :doc do
  desc 'Generate documentation for the application'
  RDoc::Task.new('app') { |rdoc|
    rdoc.rdoc_dir = 'public/doc'
    rdoc.title    = 'Sequencescape Studies'
    rdoc.template = 'doc/template.rb'
    rdoc.options << '--line-numbers' << '--inline-source'
    rdoc.rdoc_files.include('doc/README_FOR_APP')
    rdoc.rdoc_files.include('app/**/*.rb')
    rdoc.rdoc_files.include('lib/**/*.rb')
  }
end
