# frozen_string_literal: true

# All portions Copyright (c) 2010 The Wellcome Trust Sanger Institute

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#   name: 'acts_as_descriptoable',
#   description: 'Allows model fields and values to be dynamically extended.',
#   homepage: 'http://www.sanger.ac.uk/Users/mw4/ruby/rails/acts_as_descriptable',
#   version: '1.0',
#   author_link: 'http://www.sanger.ac.uk/Users/mw4/',
#   author_name: 'Matt Wood'

module ActsAsDescriptable # :nodoc:
  def self.included(base)
    base.class_eval do
      serialize :descriptors
      serialize :descriptor_fields, Array
    end
  end

  def descriptors
    descriptor_fields.filter_map do |field|
      next if field.blank?

      Descriptor.new(name: field, value: descriptor_value(field))
    end
  end

  def descriptor_value(key)
    descriptor_hash.fetch(key, '')
  end

  def add_descriptor(descriptor)
    write_attribute(:descriptors, descriptor_hash.merge(descriptor.name => descriptor.value))
    write_attribute(:descriptor_fields, descriptor_fields.push(descriptor.name))
  end

  def descriptor_hash
    read_attribute(:descriptors) || {}
  end
end
