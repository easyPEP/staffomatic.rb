> **Archived (2026-11-20).** This gem talks to the old Staffomatic API v3. For the current API see **https://developers.staffomatic.com**.
> Only remaining consumer: easyPEP/staffomatic_add_on_personio_sync, pinned to tag `v4.0.0`. Unarchive if it needs a fix.

# Staffomatic

Ruby toolkit for the Staffomatic API

## Philosophy

API wrappers [should reflect the idioms of the language in which they were
written][wrappers]. Staffomatic.rb wraps the [Staffomatic API][staffomatic-api] in a flat API
client that follows Ruby conventions and requires little knowledge of REST.

[wrappers]: http://wynnnetherland.com/journal/what-makes-a-good-api-wrapper
[staffomatic-api]: http://staffomatic.com

## Quick start

Install via Rubygems

    gem install staffomatic

... or add to your Gemfile

    gem "staffomatic", "~> 3.0"

### Making requests

API methods are available as module methods (consuming module-level
configuration) or as client instance methods.

```ruby
# Provide authentication credentials
Staffomatic.configure do |c|
  c.email = 'test@example.com'
  c.password = 'supersafepassword!'
  c.api_endpoint = 'https://api.staffomaticapp.com/v3/example-account-subdoamin'
end

# Fetch the current user
Staffomatic.user
```
or

```ruby
# Provide authentication credentials
client = Staffomatic::Client.new(:email => 'test@example.com', :password => 'supersafepassword!', :api_endpoint => 'https://api.staffomaticapp.com/v3/example-account-subdoamin')
# Fetch the current user
client.user
```

### Consuming resources

Most methods return a `Resource` object which provides dot notation and `[]`
access for fields returned in the API response.

```ruby
# Fetch a user
user = Staffomatic.user '493'
puts user.email
# => "admin@example.com"
puts user.fields
# => <Set: {:created_at, :updated_at, :id, :first_name, :last_name, :account_id, :account_owner, :email, :locale, :full_name, :role, :image, :phone_number_mobile, :phone_number_office, :company, :street, :additional_street, :zip, :city, :country, :invitation_accepted_at, :max_vacation_days, :comments_count, :attachments_count, :commentable, :attachable, :approved_absences_hours, :max_hours_per_month, :department_ids, :invitation_created_at, :invitation_token, :locked_at, :shift_category_ids, :invited_by_id}>
puts user[:company]
# => "Pouros, Gleichner and Homenick"
```

**Note:** URL fields are culled into a separate `.rels` collection for easier
[Hypermedia](#hypermedia-agent) support.

### Accessing HTTP responses

While most methods return a `Resource` object or a Boolean, sometimes you may
need access to the raw HTTP response headers. You can access the last HTTP
response with `Client#last_response`:

```ruby
user      = Staffomatic.user '493'
response  = Staffomatic.last_response
etag      = response.headers[:etag]
```

## Authentication

Staffomatic supports the various [authentication methods supported by the Staffomatic
API][auth]:

### Basic Authentication

Using your Staffomatic username and password is the easiest way to get started
making authenticated requests:

```ruby
client = Staffomatic::Client.new \
  :email    => 'test@example.com',
  :password => 'supersafepassword',
  :account => 'example-account-subdoamin'

user = client.user
user.email
# => "admin@example.com"
```
While Basic Authentication allows you to get started quickly, OAuth access
tokens are the preferred way to authenticate on behalf of users.

## Pagination

Many Staffomatic API resources are [paginated][]. While you may be tempted to start
adding `:page` parameters to your calls, the API returns links to the next,
previous, and last pages for you in the `Link` response header as [Hypermedia
link relations](#hypermedia-agent).

```ruby
users = Staffomatic.all_users :per_page => 100
users.concat Staffomatic.last_response.rels[:next].get.data
```

### Auto pagination

For smallish resource lists, Staffomatic provides auto pagination. When this is
enabled, calls for paginated resources will fetch and concatenate the results
from every page into a single array:

```ruby
Staffomatic.auto_paginate = true
users = Staffomatic.all_users
users.length

# => 702
```

**Note:** While Staffomatic auto pagination will set the page size to the maximum
`100`, and seek to not overstep your rate limit, you probably want to use a
custom pattern for traversing large lists.

## Configuration and defaults

While `Staffomatic::Client` accepts a range of options when creating a new client
instance, Staffomatic's configuration API allows you to set your configuration
options at the module level. This is particularly handy if you're creating a
number of client instances based on some shared defaults.

### Configuring module defaults

Every writable attribute in {Staffomatic::Configurable} can be set one at a time:

```ruby
Staffomatic.account = 'example-account-subdoamin.staffomatic.com/api/v3'
```

or in batch:

```ruby
Staffomatic.configure do |c|
  c.account = 'example-account-subdoamin.staffomatic.com/api/v3'
end
```

### Using ENV variables

Default configuration values are specified in {Staffomatic::Default}. Many
attributes will look for a default value from the ENV before returning
Staffomatic's default.

```ruby
# Given $STAFFOMATIC_ACCOUNT is "example-account-subdoamin.staffomatic.com"
Staffomatic.api_endpoint

# => "http://example-account-subdoamin.staffomatic.com/api/v3"
```

Deprecation warnings and API endpoints in development preview warnings are
printed to STDOUT by default, these can be disabled by setting the ENV
`STAFFOMATIC_SILENT=true`.

## Hypermedia agent

Starting in version 3.0, Staffomatic is [hypermedia][]-enabled. Under the hood,
{Staffomatic::Client} uses [Sawyer][], a hypermedia client built on [Faraday][].

## Advanced usage

Since Staffomatic employs [Faraday][faraday] under the hood, some behavior can be
extended via middleware.

### Debugging

Often, it helps to know what Staffomatic is doing under the hood. You can add a
logger to the middleware that enables you to peek into the underlying HTTP
traffic:

```ruby
stack = Faraday::RackBuilder.new do |builder|
  builder.response :logger
  builder.use Staffomatic::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
Staffomatic.middleware = stack
Staffomatic.user '493'
```

See the [Faraday README][faraday] for more middleware magic.

### Caching

If you want to boost performance, stretch your API rate limit, or avoid paying
the hypermedia tax, you can use [Faraday Http Cache][cache].

Add the gem to your Gemfile

    gem 'faraday-http-cache'

Next, construct your own Faraday middleware:

```ruby
stack = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::HttpCache
  builder.use Staffomatic::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
Staffomatic.middleware = stack
```

Once configured, the middleware will store responses in cache based on ETag
fingerprint and serve those back up for future `304` responses for the same
resource. See the [project README][cache] for advanced usage.


[cache]: https://github.com/plataformatec/faraday-http-cache
[faraday]: https://github.com/lostisland/faraday

## Hacking on Staffomatic.rb

If you want to hack on Staffomatic locally, we try to make [bootstrapping the
project][bootstrapping] as painless as possible. To start hacking, clone and run:

    script/bootstrap

This will install project dependencies and get you up and running. If you want
to run a Ruby console to poke on Staffomatic, you can crank one up with:

    script/console

Using the scripts in `./scripts` instead of `bundle exec rspec`, `bundle
console`, etc.  ensures your dependencies are up-to-date.

### Running and writing new tests

Staffomatic uses [VCR][] for recording and playing back API fixtures during test
runs. These cassettes (fixtures) are part of the Git project in the `spec/cassettes`
folder. If you're not recording new cassettes you can run the specs with existing
cassettes with:

    script/test

Staffomatic uses environmental variables for storing credentials used in testing.
If you are testing an API endpoint that doesn't require authentication, you
can get away without any additional configuration. For the most part, tests
use an authenticated client, using a token stored in `ENV['STAFFOMATIC_TEST_TOKEN']`.
There are several different authenticating method's used accross the api.
Here is the full list of configurable environmental variables for testing
Staffomatic:

ENV Variable | Description |
:-------------------|:-----------------|
`STAFFOMATIC_TEST_EMAIL`| Staffomatic login email (preferably one created specifically for testing against).
`STAFFOMATIC_TEST_PASSWORD`| Password for the test Staffomatic login.
`STAFFOMATIC_TEST_TOKEN` | [Personal Access Token](https://staffomatic.com/blog/1509-personal-api-tokens) for the test Staffomatic login.
`STAFFOMATIC_TEST_CLIENT_ID` | Test OAuth application client id.
`STAFFOMATIC_TEST_CLIENT_SECRET` | Test OAuth application client secret.
`STAFFOMATIC_TEST_SCHEME` | Test organization.

Since we periodically refresh our cassettes, please keep some points in mind
when writing new specs.

* **Specs should be idempotent**. The HTTP calls made during a spec should be
  able to be run over and over. This means deleting a known resource prior to
  creating it if the name has to be unique.
* **Specs should be able to be run in random order.** If a spec depends on
  another resource as a fixture, make sure that's created in the scope of the
  spec and not depend on a previous spec to create the data needed.
* **Do not depend on authenticated user info.** Instead of asserting
  actual values in resources, try to assert the existence of a key or that a
  response is an Array. We're testing the client, not the API.

[bootstrapping]: http://wynnnetherland.com/linked/2013012801/bootstrapping-consistency
[VCR]: https://staffomatic.com/vcr/vcr

## Supported Ruby Versions

This library aims to support and is [tested against][travis] the following Ruby
implementations:

* Ruby 1.9.2
* Ruby 1.9.3
* Ruby 2.0.0
* Ruby 2.1.0

If something doesn't work on one of these Ruby versions, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, but support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be responsible for providing patches in a timely
fashion. If critical issues for a particular implementation exist at the time
of a major release, support for that Ruby version may be dropped.

[travis]: https://travis-ci.org/staffomatic/staffomatic.rb

## Versioning

This library aims to adhere to [Semantic Versioning 2.0.0][semver]. Violations
of this scheme should be reported as bugs. Specifically, if a minor or patch
version is released that breaks backward compatibility, that version should be
immediately yanked and/or a new version should be immediately released that
restores compatibility. Breaking changes to the public API will only be
introduced with new major versions. As a result of this policy, you can (and
should) specify a dependency on this gem using the [Pessimistic Version
Constraint][pvc] with two digits of precision. For example:

    spec.add_dependency 'staffomatic', '~> 3.0'

[semver]: http://semver.org/
[pvc]: http://docs.rubygems.org/read/chapter/16#page74

## License

Copyright (c) 2013-2017 Kalle Saas

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Github License

Copyright (c) 2009-2014 Wynn Netherland, Adam Stacoviak, Erik Michaels-Ober

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
