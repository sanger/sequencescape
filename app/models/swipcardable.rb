module Swipcardable

  def swipcard_code=(code)
    self.encrypted_swipcard_code= User.encrypt_swipcard_code(code)
  end

  def swipcard_code? 
    encrypted_swipcard_code?
  end


  def compare_swipcard_code(code)
    encrypt_swipcard_code(code) == encrypted_swipcard_code
  end


  def self.included(base)
    base.class_eval do
      def self.encrypt_swipcard_code(code)
        User.encrypt(code, nil)
      end
      # won't work, because of the salt.
      named_scope :with_swipcard_code, lambda { |*swipcard_codes| { :conditions => { :encrypted_swipcard_code => swipcard_codes.flatten.map { |sw| encrypt_swipcard_code(sw)   } } } }
    end
  end

end
