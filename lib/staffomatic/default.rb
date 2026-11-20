require 'staffomatic/response/raise_error'
require 'staffomatic/version'

module Staffomatic

  # Default configuration options for {Client}
  module Default

    # Default API SCHEME
    SCHEME = "https".freeze

    # Default User Agent header string
    USER_AGENT = "Staffomatic Ruby Gem #{Staffomatic::VERSION}".freeze

    # Default Content Type header string
    CONTENT_TYPE = "application/json".freeze

    # Default media type
    MEDIA_TYPE   = "application/vnd.staffomatic.v3+json"

    RACK_BUILDER_CLASS = Faraday::RackBuilder

    # Default Faraday middleware stack
    MIDDLEWARE = RACK_BUILDER_CLASS.new do |builder|
      builder.use Staffomatic::Response::RaiseError
      builder.adapter Faraday.default_adapter
    end

    class << self

      # Configuration options
      # @return [Hash]
      def options
        Hash[Staffomatic::Configurable.keys.map{|key| [key, send(key)]}]
      end

      # Default access token from ENV
      # @return [String]
      def access_token
        ENV['STAFFOMATIC_ACCESS_TOKEN']
      end

      # Default url scheme from ENV or {SCHEME}
      # @return [String]
      def scheme
        ENV['STAFFOMATIC_SCHEME'] || SCHEME
      end

      # Default API endpoint from ENV or build from ENV
      # @return [String]
      def api_endpoint
        ENV['API_ENDPOINT'] || "https://api.staffomaticapp.com/v3/#{account}"
      end

      # Default account from ENV
      # @return [String]
      def account
        ENV['STAFFOMATIC_ACCOUNT']
      end

      # Default pagination preference from ENV
      # @return [String]
      def auto_paginate
        ENV['STAFFOMATIC_AUTO_PAGINATE']
      end

      # Default OAuth app key from ENV
      # @return [String]
      def client_id
        ENV['STAFFOMATIC_CLIENT_ID']
      end

      # Default OAuth app secret from ENV
      # @return [String]
      def client_secret
        ENV['STAFFOMATIC_SECRET']
      end

      # Default options for Faraday::Connection
      # @return [Hash]
      def connection_options
        {
          :headers => {
            :accept => default_media_type,
            :user_agent => user_agent
          }
        }
      end

      # Default media type from ENV or {MEDIA_TYPE}
      # @return [String]
      def default_media_type
        ENV['STAFFOMATIC_DEFAULT_MEDIA_TYPE'] || MEDIA_TYPE
      end

      # Default Staffomatic email for Basic Auth from ENV
      # @return [String]
      def email
        ENV['STAFFOMATIC_EMAIL']
      end

      # Default middleware stack for Faraday::Connection
      # from {MIDDLEWARE}
      # @return [String]
      def middleware
        MIDDLEWARE
      end

      # Default Staffomatic password for Basic Auth from ENV
      # @return [String]
      def password
        ENV['STAFFOMATIC_PASSWORD']
      end

      # Default pagination page size from ENV
      # @return [Fixnum] Page size
      def per_page
        page_size = ENV['STAFFOMATIC_PER_PAGE']

        page_size.to_i if page_size
      end

      # Default proxy server URI for Faraday connection from ENV
      # @return [String]
      def proxy
        ENV['STAFFOMATIC_PROXY']
      end

      # Default User-Agent header string from ENV or {USER_AGENT}
      # @return [String]
      def user_agent
        ENV['STAFFOMATIC_USER_AGENT'] || USER_AGENT
      end

      # Default User-Agent header string from ENV or {USER_AGENT}
      # @return [String]
      def content_type
        ENV['STAFFOMATIC_CONTENT_TYPE'] || CONTENT_TYPE
      end

    end
  end
end
