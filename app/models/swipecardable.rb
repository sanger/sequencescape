module Swipecardable

  def swipecard_code=(code)
    self.encrypted_swipecard_code= User.encrypt_swipecard_code(code)
  end

  def swipecard_code?
    encrypted_swipecard_code?
  end


  def compare_swipecard_code(code)
    User.encrypt_swipecard_code(code) == encrypted_swipecard_code
  end


  def self.included(base)
    base.class_eval do
      def self.encrypt_swipecard_code(code)
        User.encrypt(code, nil)
      end
      # won't work, because of the salt.
      named_scope :with_swipecard_code, lambda { |*swipecard_codes| { :conditions => { :encrypted_swipecard_code => swipecard_codes.flatten.map { |sw| encrypt_swipecard_code(sw)   } } } }
    end
  end

end
