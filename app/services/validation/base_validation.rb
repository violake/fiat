module Fiat
  class BaseValidation
    def self.validate(payment)
      @error = ""
      return @error.size == 0 ? true : false, @error
    end

    def self.datetime_valid(date)
      begin
        Time.zone.parse(date)
        return ""
      rescue Exception=>e
        return "[error date] " + date
      end
    end

  end
end