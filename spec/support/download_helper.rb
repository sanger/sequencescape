# frozen_string_literal: true

module DownloadHelpers
  TIMEOUT = 5
  PATH = Rails.root.join('tmp', 'downloads')

  def self.downloads
    create_directory unless PATH.exist?
    PATH.children
  end

  def self.downloaded_file(file, timeout: TIMEOUT)
    wait_for_download(file, timeout)
    File.read(PATH.join(file)).tap do |_|
      remove_downloads
    end
  end

  def self.wait_for_download(file, timeout = TIMEOUT)
    Timeout.timeout(timeout) do
      sleep 0.1 until downloaded?(file)
    end
  end

  def self.downloaded?(file)
    !downloading? && PATH.join(file).exist?
  end

  def self.downloading?
    downloads.grep(/\.part$/).any?
  end

  def self.remove_downloads
    FileUtils.rm_r(downloads, force: true)
  end

  def self.create_directory
    PATH.parent.mkdir unless PATH.parent.exist?
    PATH.mkdir
  end
end
