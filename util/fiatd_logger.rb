require "logger"

# category of log level to different output with log info as json
class FiatdLogger
  LOG_LEVEL = { stdout: [:debug , :info , :warn],
                stderr: [:error , :fatal , :unknown]
              }

  def initialize(log_level)
    @loggers = {}
    LOG_LEVEL.each do |out, levels|
      logger = Logger.new(eval(out.to_s.upcase))
      logger.level = Logger.const_get(log_level)

      logger.formatter = \
      proc do |severity, datetime, progname, msg|
        %Q|{"severity": "#{severity}", "timestamp": "#{datetime.to_s}", "message": #{msg}}\n|
      end

      levels.each { |level| @loggers[level] = logger }
    end
  end

  LOG_LEVEL.each do |_, levels|
    levels.each do |level|
      define_method(level) do |message|
        @loggers[level].send(level, message)
      end
    end
  end
end