module ActiveRecord::ExtraValidations
  def validates_unassigned(*attrs)
    validates_each(*attrs) { |record, attr, value| record.errors.add(attr, 'cannot be assigned') if value.present? }
  end
end

class ActiveRecord::Base
  extend ActiveRecord::ExtraValidations
end
