require 'sawyer'
require 'staffomatic/arguments'
require 'staffomatic/configurable'
require 'staffomatic/authentication'
require 'staffomatic/rate_limit'
require 'staffomatic/user'
require 'staffomatic/client/authorizations'
require 'staffomatic/client/users'
require 'staffomatic/client/account'
require 'staffomatic/client/locations'
require 'staffomatic/client/schedules'
require 'staffomatic/client/departments'
require 'staffomatic/client/shifts'
require 'staffomatic/client/applications'
require 'staffomatic/client/absences'
require 'staffomatic/client/absence_types'
require 'staffomatic/client/special_days'
require 'staffomatic/client/news_items'
require 'staffomatic/client/work_reports'
require 'staffomatic/client/work_timers'
require 'staffomatic/client/break_timers'
require 'staffomatic/client/rate_limit'

module Staffomatic

  # Client for the Staffomatic API
  #
  # @see https://developer.github.com
  class Client

    include Staffomatic::Authentication
    include Staffomatic::Configurable
    include Staffomatic::Client::RateLimit
    include Staffomatic::Client::Authorizations
    include Staffomatic::Client::Users
    include Staffomatic::Client::Account
    include Staffomatic::Client::Locations
    include Staffomatic::Client::Schedules
    include Staffomatic::Client::Departments
    include Staffomatic::Client::Shifts
    include Staffomatic::Client::Applications
    include Staffomatic::Client::Absences
    include Staffomatic::Client::AbsenceTypes
    include Staffomatic::Client::SpecialDays
    include Staffomatic::Client::WorkReports
    include Staffomatic::Client::WorkTimers
    include Staffomatic::Client::BreakTimers
    include Staffomatic::Client::NewsItems

    # Header keys that can be passed in options hash to {#get},{#head}
    CONVENIENCE_HEADERS = Set.new([:accept, :content_type])

    def initialize(options = {})
      # Use options passed in, but fall back to module defaults
      Staffomatic::Configurable.keys.each do |key|
        instance_variable_set(:"@#{key}", options[key] || Staffomatic.instance_variable_get(:"@#{key}"))
      end
    end

    # Compares client options to a Hash of requested options
    #
    # @param opts [Hash] Options to compare with current client options
    # @return [Boolean]
    def same_options?(opts)
      opts.hash == options.hash
    end

    # Text representation of the client, masking tokens and passwords
    #
    # @return [String]
    def inspect
      inspected = super

      # mask password
      inspected = inspected.gsub! @password, "*******" if @password
      # Only show last 4 of token, secret
      if @access_token
        inspected = inspected.gsub! @access_token, "#{'*'*36}#{@access_token[36..-1]}"
      end
      if @client_secret
        inspected = inspected.gsub! @client_secret, "#{'*'*36}#{@client_secret[36..-1]}"
      end

      inspected
    end

    # Make a HTTP GET request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Query and header params for request
    # @return [Sawyer::Resource]
    def get(url, options = {})
      request :get, url, parse_query_and_convenience_headers(options)
    end

    # Make a HTTP POST request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Body and header params for request
    # @return [Sawyer::Resource]
    def post(url, options = {})
      request :post, url, options
    end

    # Make a HTTP PUT request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Body and header params for request
    # @return [Sawyer::Resource]
    def put(url, options = {})
      request :put, url, options
    end

    # Make a HTTP PATCH request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Body and header params for request
    # @return [Sawyer::Resource]
    def patch(url, options = {})
      request :patch, url, options
    end

    # Make a HTTP DELETE request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Query and header params for request
    # @return [Sawyer::Resource]
    def delete(url, options = {})
      request :delete, url, options
    end

    # Make a HTTP HEAD request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Query and header params for request
    # @return [Sawyer::Resource]
    def head(url, options = {})
      request :head, url, parse_query_and_convenience_headers(options)
    end

    # Make one or more HTTP GET requests, optionally fetching
    # the next page of results from URL in Link response header based
    # on value in {#auto_paginate}.
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Query and header params for request
    # @param block [Block] Block to perform the data concatination of the
    #   multiple requests. The block is called with two parameters, the first
    #   contains the contents of the requests so far and the second parameter
    #   contains the latest response.
    # @return [Sawyer::Resource]
    def paginate(url, options = {}, &block)
      opts = parse_query_and_convenience_headers(options.dup)
      if @auto_paginate || @per_page
        opts[:query][:per_page] ||=  @per_page || (@auto_paginate ? 100 : nil)
      end

      data = request(:get, url, opts)

      if @auto_paginate
        while has_next_page? && rate_limit.remaining > 0
          @last_response = @last_response.rels[:next].get
          if block_given?
            yield(data, @last_response)
          else
            data.concat(@last_response.data) if @last_response.data.is_a?(Array)
          end
        end

      end

      data
    end

    # We have to check if sawyer found a next page and check the data of the
    # next response is not an empty array
    #
    # @return [Boolean] True on next page and data in next page, false otherwise
    def has_next_page?
      @last_response.rels[:next] && @last_response.rels[:next].get.data.any?
    end

    # Hypermedia agent for the Staffomatic API
    #
    # @return [Sawyer::Agent]
    def agent
      @agent ||= Sawyer::Agent.new(api_endpoint, sawyer_options) do |http|
        http.headers[:accept] = default_media_type
        http.headers[:user_agent] = user_agent
        http.headers[:content_type] = content_type
        if basic_authenticated?
          http.request :authorization, :basic, @email, @password
        elsif token_authenticated?
          # Original octocit implementation: http.authorization 'token', @access_token
          # Doorkeeper aka Oauth `http://oauth.net/documentation/`
          http.headers['Authorization'] = "Bearer #{@access_token}"
        elsif application_authenticated?
          http.params = http.params.merge application_authentication
        end
      end
    end

    # Fetch the root resource for the API
    #
    # @return [Sawyer::Resource]
    def root
      get "/api"
    end

    # Response for last HTTP request
    #
    # @return [Sawyer::Response]
    def last_response
      @last_response if defined? @last_response
    end

    # Duplicate client using client_id and client_secret as
    # Basic Authentication credentials.
    # @example
    #   Staffomatic.client_id = "foo"
    #   Staffomatic.client_secret = "bar"
    #
    #   # GET https://api.staffomatic.com/?client_id=foo&client_secret=bar
    #   Staffomatic.get "/api"
    #
    #   Staffomatic.client.as_app do |client|
    #     # GET https://foo:bar@api.staffomatic.com/
    #     client.get "/api"
    #   end
    def as_app(key = client_id, secret = client_secret, &block)
      if key.to_s.empty? || secret.to_s.empty?
        raise ApplicationCredentialsRequired, "client_id and client_secret required"
      end
      app_client = self.dup
      app_client.client_id = app_client.client_secret = nil
      app_client.email    = key
      app_client.password = secret

      yield app_client if block_given?
    end

    # Set account for authentication
    #
    # @param value [String] Staffomatic account
    def account=(value)
      reset_agent
      @account = value
    end

    # Build api_enpoint from options or defaults
    #
    # @return [String] Base URL for API requests.
    def api_endpoint=(value)
      reset_agent
      @api_endpoint = value
    end

    # Set value to build api_enpoint
    #
    # @param value [String] Staffomatic scheme
    def scheme=(value)
      reset_agent
      @scheme = value
    end

    # Set email for authentication
    #
    # @param value [String] Staffomatic email
    def email=(value)
      reset_agent
      @email = value
    end

    # Set password for authentication
    #
    # @param value [String] Staffomatic password
    def password=(value)
      reset_agent
      @password = value
    end

    # Set OAuth access token for authentication
    #
    # @param value [String] 40 character Staffomatic OAuth access token
    def access_token=(value)
      reset_agent
      @access_token = value
    end

    # Set OAuth app client_id
    #
    # @param value [String] 20 character Staffomatic OAuth app client_id
    def client_id=(value)
      reset_agent
      @client_id = value
    end

    # Set OAuth app client_secret
    #
    # @param value [String] 40 character Staffomatic OAuth app client_secret
    def client_secret=(value)
      reset_agent
      @client_secret = value
    end

    # Wrapper around Kernel#warn to print warnings unless
    # STAFFOMATIC_SILENT is set to true.
    #
    # @return [nil]
    def staffomatic_warn(*message)
      unless ENV['STAFFOMATIC_SILENT']
        warn message
      end
    end

    private

    def reset_agent
      @agent = nil
    end

    def request(method, path, data, options = {})
      if data.is_a?(Hash)
        options[:query]   = data.delete(:query) || {}
        options[:headers] = data.delete(:headers) || {}
        if accept = data.delete(:accept)
          options[:headers][:accept] = accept
        end
      end
      @last_response = response = agent.call(method, URI::Parser.new.escape(path.to_s), data, options)
      response.data
    end

    # Executes the request, checking if it was successful
    #
    # @return [Boolean] True on success, false otherwise
    def boolean_from_response(method, path, options = {})
      request(method, path, options)
      @last_response.status == 204
    rescue Staffomatic::NotFound
      false
    end


    def sawyer_options
      opts = {
        :links_parser => Sawyer::LinkParsers::Simple.new
      }
      conn_opts = @connection_options
      conn_opts[:builder] = @middleware if @middleware
      conn_opts[:proxy] = @proxy if @proxy
      opts[:faraday] = Faraday.new(conn_opts)

      opts
    end

    def parse_query_and_convenience_headers(options)
      headers = options.fetch(:headers, {})
      CONVENIENCE_HEADERS.each do |h|
        if header = options.delete(h)
          headers[h] = header
        end
      end
      query = options.delete(:query)
      opts = {:query => options}
      opts[:query].merge!(query) if query && query.is_a?(Hash)
      opts[:headers] = headers unless headers.empty?

      opts
    end
  end
end
