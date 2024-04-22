# frozen_string_literal: true
class Health
  attr_reader :status, :message, :details

  def initialize
    @status = :ok
    @message = []
    @details = { vm_stas: RubyVM.stat }
    check
  end

  def check
    @message << 'No problems detected.' if status == :ok
  end
end
