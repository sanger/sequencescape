class Core::Io::List
  include Core::Benchmarking

  def initialize(command, objects)
    @command, @container = command, command.send(:container)
    @objects = objects.map { |o| Core::Io::Registry.instance.lookup(o.class).create!(@container, o) }
    @current_page, @last_page = [ 1, objects.current_page ].max, [ 1, objects.total_pages ].max
  end

  def as_json(options = nil)
    benchmark("I/O #{self.class.name}") do
      uuids_to_ids = {}
      object_contents = @objects.map { |o| o.object_json(uuids_to_ids, options) }

      json = @command.as_json(options)
      json[:actions].merge!(pagination_actions)
      json.merge!(
        :uuids_to_ids             => uuids_to_ids,
        @command.class.json_root  => object_contents
      )
      json
    end
  end

private

  def pagination_actions
    actions_to_page = {
      :first => 1,
      :last  => @last_page,
      :read  => @current_page
    }
    actions_to_page[:previous] = @current_page-1 unless @current_page == 1
    actions_to_page[:next]     = @current_page+1 unless @current_page == @last_page
    Hash[actions_to_page.map { |k,v| [ k, @command.action_for_page(v) ] }]
  end
end
