#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class Core::Io::List
  include Core::Benchmarking

  def initialize(command, objects)
    @command, @container = command, command.send(:container)
    @objects = objects.map { |o| Core::Io::Registry.instance.lookup(o.class).create!(@container, o) }
    @current_page, @last_page = [ 1, objects.current_page ].max, [ 1, objects.total_pages ].max
  end

  delegate :action_for_page, :to => :@command

  def pagination_actions
    {
      :first => action_for_page(1),
      :last  => action_for_page(@last_page),
      :read  => action_for_page(@current_page)
    }.tap do |actions_to_page|
      actions_to_page[:previous] = action_for_page(@current_page-1) unless @current_page == 1
      actions_to_page[:next]     = action_for_page(@current_page+1) unless @current_page == @last_page
    end
  end
  private :pagination_actions
end
