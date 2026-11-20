require 'faraday'
require 'staffomatic/error'

module Staffomatic
  # Faraday response middleware
  module Response

    # This class raises an Staffomatic-flavored exception based
    # HTTP status codes returned by the API
    class RaiseError < Faraday::Middleware
      def on_complete(response)
        if error = Staffomatic::Error.from_response(response)
          raise error
        end
      end
    end
  end
end
