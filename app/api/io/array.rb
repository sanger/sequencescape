class ::Io::Array
  extend ::Core::Io::Collection

  def self.post_process(json)
    json.delete('actions')
  end
end
