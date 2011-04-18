class ::Io::WillPaginate::Collection
  extend ::Core::Io::Collection

  def self.size_for(results)
    results.total_entries
  end
end
