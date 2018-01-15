module IlluminaHtp::Requests
  class GBSRequest < StdLibraryRequest

    fragment_size_details(:no_default, :no_default)

    Metadata.class_eval do
      belongs_to :primer_panel
      association(:primer_panel, :name)
    end

    def update_pool_information(pool_information)
      super
      pool_information[:primer_panel] = request_metadata.primer_panel
    end
  end
end
