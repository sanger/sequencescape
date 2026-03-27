# frozen_string_literal: true
module Informatics
  module Globals
    @@application = nil
    @@defaults = nil

    def application
      @@application
    end

    def application=(app)
      @@application = app
    end

    def defaults
      @@defaults
    end

    def defaults=(incoming)
      @@defaults = incoming
    end

    def global_searchable_classes
      [Barcode, Project, Study, Sample, Labware, AssetGroup, Request, Supplier, Submission]
    end

    def search_options
      global_searchable_classes.map do |klass|
        [klass.name, klass.name]
      end + [['Cost Code', 'Project'], ['All (wildcard)', 'All (wildcard)'], ['All', 'All']]
    end
  end
end
