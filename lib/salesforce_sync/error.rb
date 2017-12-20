module SalesforceSync
  class Error < StandardError
    attr_reader :message, :klass

    def initialize(message, klass)
      @message = message
      @klass = klass
    end

    def raise_error
      if SalesforceSync.config.raise_on_airbrake
        options = {
          error_class: klass,
          error_message: error_message,
          environment_name: defined?(Rails) ? Rails.env : :no_environment_defined
        }

        ::Airbrake.notify(self.class, options)
      end

      raise error_message
    end

    def error_message
      "#{klass} : #{message}"
    end
  end
end
