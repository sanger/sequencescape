class ::Io::WillPaginate::Collection
  extend ::Core::Io::Collection

  class << self
    def size_for(results)
      results.total_entries
    end
    private :size_for
  end
end
