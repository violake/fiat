module Fiat

  module Timezone
    @local_zone = nil
    
    def set_timezone(timezone)
      regex = /^[+\-](0\d|1[0-2]):([0-5]\d)$/
      return timezone unless regex.match(timezone)
      zone = timezone.split(":")
      @local_zone = Time.zone
      Time.zone = (zone[0] + "." + ((zone[1].to_f)/60*100).to_i.to_s).to_f.hours
    end
  
    def timezone_reset
      Time.zone = @local_zone
    end
  
    def timezone_changed?
      @local_zone ? true : false
    end
    
  end

end