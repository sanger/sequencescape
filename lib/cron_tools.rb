require 'time'
require 'log4r'
include Log4r

module ActiveRecord
  class Base
    #Hello monkeypatch!
    def self.each_paginated(per_page, options = {}, &block)
      sql = construct_finder_sql(options.dup.merge({ :select => "id" }))
      all_ids = connection.select_all(sql).map { |h| h["id"] }
      all_count = all_ids.length
      at_a_time = 0..(per_page-1)
      begin
        page_ids = all_ids.slice!(at_a_time)
        find(:all, :conditions => [ "id IN (?)", page_ids ] ).each &block
#        puts "  ( #{ [page_ids.first, (all_ids.last || page_ids.last) ].join('..') } )"
        #GC.start # only neccessary at certaing page sizes it seems? (go ask ruby-src/gc.c)
#warn "#{self}: one, two, miss a few..."; all_ids = []
      end until all_ids.empty?
      return all_count
    end
  end
end

module TimeKeeping
  def self.start!
    @start = Time.now
  end

  def self.finish!
    @finish = Time.now
  end

  def self.running_time
    "#{(((@finish - @start).abs)/60)} minutes"
  end
end

def custom_log(script_name)
  log_file = "./log/#{script_name}-#{RAILS_ENV}-mart-builder-#{Time.now.strftime('%Y%m%d%H%M%S')}.log"
  # create a logger
  console_formatter = Log4r::PatternFormatter.new(:pattern => "[%l] [#%c] %d :: %m")
  @log = Log4r::Logger.new 'log'
#  @log.outputters = Log4r::StdoutOutputter.new 'console', :formatter => console_formatter
  @log.level = Log4r::INFO

  file_format = PatternFormatter.new(:pattern => "[ %d ] %l\t %m")
  @log.add FileOutputter.new('fileOutputter', :filename => log_file, :trunc => false, :formatter=>file_format)
end
