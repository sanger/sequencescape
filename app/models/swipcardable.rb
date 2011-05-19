module Swipcardable

  def swipcard_code=(code)
    self.encrypted_swipcard_code= encrypt_swipcard_code(code)
  end

  def swipcard_code? 
    encrypted_swipcard_code?
  end

  def compare_swipcard_code(code)
    encrypt_swipcard_code(code) == encrypted_swipcard_code
  end

  def encrypt_swipcard_code(code)
    User.encrypt(code, login)
  end
end
