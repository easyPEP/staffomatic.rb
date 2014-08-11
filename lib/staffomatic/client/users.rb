module Staffomatic
  class Client

    # Methods for the Users API
    #
    # @see https://developer.github.com/v3/users/
    module Users

      # List all Staffomatic users
      #
      # This provides a dump of every user, in the order that they signed up
      # for Staffomatic.
      #
      # @param options [Hash] Optional options.
      # @option options [Integer] :since The integer ID of the last User that
      #   you’ve seen.
      #
      # @see https://developer.github.com/v3/users/#get-all-users
      #
      # @return [Array<Sawyer::Resource>] List of Staffomatic users.
      def all_users(options = {})
        paginate "users", options
      end

      # Get a single user
      #
      # @param user [Integer, String] Staffomatic user id.
      # @return [Sawyer::Resource]
      # @see https://developer.github.com/v3/users/#get-a-single-user
      # @see https://developer.github.com/v3/users/#get-the-authenticated-user
      # @example
      #   Staffomatic.user(493)
      def user(user=nil, options = {})
        get User.path(user), options
      end

      # Retrieve the access_token.
      #
      # @param code [String] Authorization code generated by Staffomatic.
      # @param app_id [String] Client Id we received when our application was registered with Staffomatic. Defaults to client_id.
      # @param app_secret [String] Client Secret we received when our application was registered with Staffomatic. Defaults to client_secret.
      # @return [Sawyer::Resource] Hash holding the access token.
      # @see https://developer.github.com/v3/oauth/#web-application-flow
      # @example
      #   Staffomatic.exchange_code_for_token('aaaa', 'xxxx', 'yyyy', {:accept => 'application/json'})
      def exchange_code_for_token(code, app_id = client_id, app_secret = client_secret, options = {})
        options.merge!({
          :code => code,
          :client_id => app_id,
          :client_secret => app_secret,
          :headers => {
            :content_type => 'application/json',
            :accept       => 'application/json'
          }
        })
        post "#{web_endpoint}login/oauth/access_token", options
      end

      # Validate user email and password
      #
      # @param options [Hash] User credentials
      # @option options [String] :email Staffomatic email
      # @option options [String] :password Staffomatic password
      # @return [Boolean] True if credentials are valid
      def validate_credentials(options = {})
        !self.class.new(options).user.nil?
      rescue Staffomatic::Unauthorized
        false
      end

      # Update the authenticated user
      #
      # @param options [Hash] A customizable set of options.
      # @option options [String] :name
      # @option options [String] :email Publically visible email address.
      # @option options [String] :blog
      # @option options [String] :company
      # @option options [String] :location
      # @option options [Boolean] :hireable
      # @option options [String] :bio
      # @return [Sawyer::Resource]
      # @see https://developer.github.com/v3/users/#update-the-authenticated-user
      # @example
      #   Staffomatic.update_user(:name => "Erik Michaels-Ober", :email => "sferik@gmail.com", :company => "Code for America", :location => "San Francisco", :hireable => false)
      def update_user(options)
        patch "user", options
      end

    end

    private
    # convenience method for constructing a user specific path, if the user is logged in
    def user_path(user, path)
      if user == login && user_authenticated?
        "user/#{path}"
      else
        "#{User.path user}/#{path}"
      end
    end
  end
end
