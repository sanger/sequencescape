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
       [ Project, Study, Sample, Asset, AssetGroup, Request, Supplier ]
    end

    def search_options
      global_searchable_classes.map {|klass| [klass.name]*2 } << ['All',nil]
    end

  end
end
