# frozen_string_literal: true
class Health # rubocop:todo Style/Documentation
  attr_reader :status, :message, :details

  def initialize
    @status, @message = :ok, []
    @details = { vm_stas: RubyVM.stat }
    check
  end

  def check
    @message << 'No problems detected.' if status == :ok
  end
end
