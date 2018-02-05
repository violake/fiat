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

    def set_timezone_by_name(timezone_name)
      @local_zone = Time.zone
      Time.zone = timezone_name
    end
  
    def timezone_reset
      Time.zone = @local_zone if timezone_changed?
    end
  
    def timezone_changed?
      @local_zone ? true : false
    end

    def confert_time_by_zone_name(time, timezone_name)
      set_timezone_by_name(timezone_name)
      Time.zone.parse(time).utc
    rescue
      nil
    ensure
      timezone_reset
    end
    
  end

end