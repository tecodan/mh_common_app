class Country < ActiveRecord::Base
  load_mappings
  include Common::Core::Country
  include Common::Core::Country::Ca::Country
end
