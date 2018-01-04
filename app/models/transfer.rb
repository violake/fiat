require './util/timezone'

class Transfer < ApplicationRecord
  extend Fiat::Timezone
  
end