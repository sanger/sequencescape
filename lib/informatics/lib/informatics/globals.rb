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
      global_searchable_classes.map { |klass| [klass.name, klass.name] } + [['Cost Code', 'Project'], ['All', nil]]
    end
  end
end
