# frozen_string_literal: true

module DownloadHelpers
  TIMEOUT = 5
  PATH = Capybara.save_path

  def self.downloads
    PATH.children
  end

  def self.downloaded_file(file, timeout: TIMEOUT)
    wait_for_download(file, timeout)
    File.read(path_to(file)).tap do |_|
      remove_downloads
    end
  end

  def self.path_to(file)
    PATH.join(file)
  end

  def self.wait_for_download(file, timeout = TIMEOUT)
    Timeout.timeout(timeout) do
      sleep 0.1 until downloaded?(file)
    end
  rescue Timeout::Error
    raise StandardError, "Could not open #{file} after #{timeout} seconds"
  end

  def self.downloaded?(file)
    !downloading? && path_to(file).exist?
  end

  def self.downloading?
    downloads.grep(/\.part$/).any?
  end

  def self.remove_downloads
    FileUtils.rm_r(downloads, force: true)
  end
end
