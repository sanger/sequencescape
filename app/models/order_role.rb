# frozen_string_literal: true

# {OrderRole Order roles} are used to provide additional information to users to distinguish
# between two otherwise identical requests being performed for different reasons.
# They were initially added to provide quick visual distinction between mammalian and pathogen
# whole genome sequencing requests, after the two had been unified under the same {RequestType} and {LibraryType}.
#
# Essentially this solved the situation where a shared upstream process lead into two distinct downstream processes.
# In practice though this role would be better handled by other mechanisms, such as library type.
#
class OrderRole < ApplicationRecord
end
