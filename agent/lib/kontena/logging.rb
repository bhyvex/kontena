require 'logger'

module Kontena
  module Logging

    def self.initialize_logger(log_target = STDOUT, log_level = Logger::INFO)
      @logger = Logger.new(log_target)
      @logger.level = log_level
      @logger
    end

    def self.logger
      defined?(@logger) ? @logger : initialize_logger
    end

    def self.logger=(log)
      @logger = (log ? log : Logger.new('/dev/null'))
    end

    # @return [Logger]
    def logger
      Kontena::Logging.logger
    end

    # Send a debug message
    # @param [String] string
    def debug(string)
      logger.debug(self.class.name.gsub('Kontena::', '')) { string }
    end

    # Send a info message
    # @param [String] string
    def info(string)
      logger.info(self.class.name) { string }
    end

    # Send a warning message
    # @param [String] string
    def warn(string)
      logger.warn(self.class.name) { string }
    end

    # Send an error message
    # @param [String] string
    def error(string)
      logger.error(self.class.name) { string }
    end

    # Send an error message for an exception
    # @param [Exception] exception
    def error_exception(exception, string)
      logger.error(self.class.name) { string }
      logger.error(self.class.name) { exception.backtrace.join("\n") }
    end
  end
end
