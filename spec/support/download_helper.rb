# frozen_string_literal: true

module DownloadHelpers
  TIMEOUT = 5
  PATH = Rails.root.join('tmp', 'downloads')

  def self.downloads
    Dir[PATH.join('*')]
  end

  def self.downloaded_file(file)
    wait_for_download
    File.read(PATH.join(file))
  end

  def self.wait_for_download
    Timeout.timeout(TIMEOUT) do
      sleep 0.5 until downloaded?
    end
  end

  def self.downloaded?
    !downloading? && downloads.any?
  end

  def self.downloading?
    downloads.grep(/\.part$/).any?
  end

  def self.remove_downloads
    FileUtils.rm_r(downloads, force: true)
  end
end
