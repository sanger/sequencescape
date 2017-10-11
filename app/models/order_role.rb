class OrderRole < ApplicationRecord
  # Order role is a basic way of categorizing otherwise similar orders.
  # It was mainly to provide a quick way of distinguishing between otherwise
  # identical request types in the Illumina-B Pipeline app.
  # Removing this will probably be low impact.
end
