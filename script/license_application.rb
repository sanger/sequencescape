#!/usr/bin/env ruby
# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
module WTSI
  ##
  # Controls the addition of license files to an application
  # WTSI::LicenseApplication.new yields itself for configuration
  # It provides the following attribute writers
  # application: The name of the application
  # initial_range: A range covering years outside the git repo
  # date_line: The line that will include date information. %s indicates where dates will be inserted
  # license_text: Sting that will be inserted at the top of each file. %s will be replaced with the application name
  class LicenseApplication
    attr_accessor :application, :initial_range, :date_line
    attr_writer :license_text

    ##
    # comment_prefix will be applied to the start of each line
    # comment_open and comment_close will wrap the start and end lines
    Filetype = Struct.new(:extension, :comment_prefix, :comment_open, :comment_close)

    def initialize
      yield self
      @license_text_compiled = @license_text % application
    end

    ##
    # Add a filetype to be tagged with copyright information
    # extension: The file extension
    # prefix: The string that will be prepended to a comment (eg. # for ruby)
    # open: The string that opens a multi-line comment (OPTIONAL)
    # close: The string that closes a multi-line comment (OPTIONAL)
    def add_filetype(extension, prefix, open = nil, close = nil)
      filetypes[extension] = Filetype.new(extension, prefix, open, close)
    end

    ##
    # Provide a root folder to exclude from the process.
    # Useful for excluding eg. the vendor folder in older rails apps.
    def exclude_folder(folder)
      excluded_folders << folder
    end

    ##
    # Indicates that files in the root directory should be excluded
    def exclude_root!
      @exclude_root = true
    end

    ##
    # Begin the license application process
    def apply_licenses
      files_to_license.each do |filename|
        TargetFile.new(filename, self).apply_license
      end
      0
    end

    ##
    # Retrieve the filetype configuration for extension
    def filetype_for(ext)
      filetypes.fetch(ext)
    end

    ##
    # Retrieve the license_text with the application included
    def license_text
      @license_text_compiled
    end

    ##
    # The initial date range in string format
    def range_string
      @rs ||= [initial_range.begin, initial_range.end].uniq.join('-')
    end

    private

    def filetypes
      @filetype ||= Hash.new
    end

    def excluded_folders
      @excluded_folders ||= Array.new
    end

    def excluded_root
      @exclude_root || false
    end

    def extension_string
      filetypes.keys.map { |ext| "*.#{ext}" }.join(' ')
    end

    def files_to_license
      `git ls-files #{extension_string}`.split.reject { |file| excluded?(file) }
    end

    def excluded?(file_path)
      path = file_path.split('/')
      return excluded_root if path.one?
      excluded_folders.include?(path.first)
    end
  end

  class TargetFile
    attr_reader :filename, :licenser, :filetype, :old_file

    def initialize(filename, licenser)
      @filename = filename
      @licenser = licenser
      @filetype = licenser.filetype_for(extension)
    end

    ##
    # Apply the license text to the given file
    # Involves the creation of a temporary file
    def apply_license
      begin
        return if existing_license?
        STDOUT.print '.'
        first_line = old_file.gets
        new_file.write(first_line) if !first_line.nil? && first_line.match(/^#!/)
        new_file.write(license_text)
        new_file.write(first_line) unless !first_line.nil? && first_line.match(/^#!/)
        old_file.each_line { |line| new_file.puts(line) }
      rescue => exception
        STDERR.puts "Something went wrong applying license to #{filename}:"
        raise exception
      ensure
        old_file.close unless old_file.closed?
        new_file.close unless @new_file.nil? || new_file.closed?
      end

      File.rename(filename, "#{filename}.tmp")
      File.rename(new_filename, filename)
      File.delete("#{filename}.tmp")
    end

    private

    def old_file
      @old_file ||= File.open(filename, 'r')
    end

    def new_file
      @new_file ||= File.new(new_filename, 'w')
    end

    def new_filename
      "#{filename}.updated"
    end

    def existing_license?
      old_file.rewind
      [
        filetype.comment_open,
        license_body
      ].join.lines.all? do |line|
        old_line = old_file.gets
        old_line = old_file.gets if !old_line.nil? && old_line.match(/^#!/)
        line == old_line
      end
    ensure
      old_file.rewind
    end

    def license_text
      [
        filetype.comment_open,
        license_body,
        license_dates,
        filetype.comment_close,
        "\n"
      ].flatten.compact.join
    end

    def license_body
      licenser.license_text.gsub(/^/, filetype.comment_prefix)
    end

    def date_stamps
      dates = updated_dates
      initial = !dates.delete('INITIAL').nil?
      dates.delete(licenser.initial_range.begin.to_s) if initial
      initial_range = initial ? [licenser.range_string] : []
      initial_range.concat(dates).join(',')
    end

    def license_dates
      [
        filetype.comment_prefix,
        licenser.date_line % date_stamps
      ]
    end

    def updated_dates
      `git log --date=short --format=format:"%ad %p" -- follow -- #{filename} |
      awk -F'[\\- ]' '{print ($4?$1:"INITIAL")}'`.split.sort.uniq
    end

    def extension
      filename.match(/\.([^\.]*)$/)[1]
    end
  end
end

WTSI::LicenseApplication.new do |config|
  config.application = 'SEQUENCESCAPE'
  config.license_text = <<HEREDOC
This file is part of %s; it is distributed under the terms of GNU General Public License version 1 or later;
Please refer to the LICENSE and README files for information on licensing and authorship of this file.
HEREDOC
  config.date_line = 'Copyright (C) %s Genome Research Ltd.'
  config.initial_range = (2007..2011)

  config.add_filetype('rb', '#')
  config.add_filetype('js', '//')
  config.add_filetype('erb', '#', '<%', '%>')

  config.exclude_folder 'lib'
  config.exclude_folder 'vendor'
end.apply_licenses
