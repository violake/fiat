module Fiat
  
  module Jhash

    def jhash(str)
      result = 0
      mul = 1
      max_mod = 2**63 - 1
      str.chars.reverse_each do |c|
          result += mul * c.ord
          result %= max_mod
          mul *= 31
      end
      result
    end

  end
end