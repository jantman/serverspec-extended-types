# ServerspecExtendedTypes

[![Build Status](https://travis-ci.org/jantman/serverspec-extended-types.svg?branch=master)](https://travis-ci.org/jantman/serverspec-extended-types)
[![Code Coverage](https://codecov.io/github/jantman/serverspec-extended-types/coverage.svg?branch=master)](https://codecov.io/github/jantman/serverspec-extended-types?branch=master)
[![Code Climate](https://codeclimate.com/github/jantman/serverspec-extended-types/badges/gpa.svg)](https://codeclimate.com/github/jantman/serverspec-extended-types)
[![Gem Version](https://img.shields.io/gem/v/serverspec-extended-types.svg)](https://rubygems.org/gems/serverspec-extended-types)
[![Total Downloads](https://img.shields.io/gem/dt/serverspec-extended-types.svg)](https://rubygems.org/gems/serverspec-extended-types)
[![Github Issues](https://img.shields.io/github/issues/jantman/serverspec-extended-types.svg)](https://github.com/jantman/serverspec-extended-types/issues)
[![Project Status: Active - The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/0.1.0/active.svg)](http://www.repostatus.org/#active)

serverspec-extended-types provides some purpose-specific types to be used with [serverspec](http://serverspec.org/) 2.x for
testing various things on a host, as well as some types for high-level integration tests that make actual requests against
services on the host.

Current types include:

* A ``virtualenv`` type to make expectations about a Python Virtualenv, its ``pip`` and ``python`` versions, and packages
  installed in it. This also works for system-wide Python if ``pip`` is installed.
* A ``http_get`` type to perform an HTTP GET request (specifying a port number, the ``Host:`` header to set, and the path
  to request) and make expectations about whether the request times out, its status code, headers, and response body.
* A ``bitlbee`` type to actually connect via IRC to a running [bitlbee](http://www.bitlbee.org/) IRC gateway and authenticate
  to it, and make expectations that the connection and authentication worked, and what version of Bitlbee is running.

This is in no way associated with or endorsed by the SeverSpec project or its developers. (When I proposed that they include
a HTTP request type, I was told that was "using [serverspec] wrong", and the GitHub issue was deleted). I imagine that,
at the least, they'd tell me that (1) these should be in SpecInfra, and (2) these aren't "proper" things for ServerSpec
to test. That being said, these are useful to me, for my purposes. I hope they're also useful to someone else.

## Installation

Add this line to your application's Gemfile:

    gem 'serverspec-extended-types'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install serverspec-extended-types

### Requirements

* [serverspec](https://rubygems.org/gems/serverspec) 2.x
* [specinfra](https://rubygems.org/gems/specinfra) 2.x

## Usage

In your spec_helper, add a line like:

    require 'serverspec_extended_types'

Then use the various types that this gem provides:

## Types

### bitlbee

The bitlbee type allows testing connectivity to a [bitlbee](http://www.bitlbee.org/) IRC gateway server.

    describe bitlbee(port, nick, password, use_ssl=false) do
      # matchers here
	end

All server communication happens during instantiation of the type; when ``describe bitlbee()`` is executed,
the type will attempt to connect to the server (with a timeout of 10 seconds) and authenticate as
the specified user, and store a number of state variables for later use by the various matchers.

This type supports SSL, but connects to the server without verifying certificates.

#### Parameters:

* __port__ - integer port number to connect to
* __nick__ - nick/username to login as
* __password__ - the password for nick
* __use_ssl__ - Boolean, whether or not to use SSL; defaults to false

#### Matchers

##### connectable?

True if the test was able to successfully connect and authenticate, false otherwise.

    describe bitlbee(port, nick, password) do
      it { should be_connectable }
	end

##### timed_out?

True if the connection is aborted by a timeout, false otherwise.

    describe bitlbee(port, nick, password) do
      it { should_not be_timed_out }
	end

##### version

Returns the Bitlbee version String.

    describe bitlbee(port, nick, password) do
      its(:version) { should match /3\.\d+\.\d+ Linux/ }
	end

### http_get

The http_get type performs an HTTP GET from the local (rspec runner) system, against
the IP address that serverspec is running against (``ENV[TARGET_HOST]``), with a
specified ``Host`` header value. The request is wrapped in a configurable-length timeout.

    describe http_get(port, host_header, path, timeout_sec=10)
      # matchers here
	end

All server communication happens during instantiation of the type; when ``describe http_get()`` is executed,
the type will attempt to issue the GET request with a default timeout of 10 seconds, and store a number of
state variables for later use by the various matchers.

#### Parameters

* __port__ - the port to make the HTTP request to
* __host_header__ - the ``Host`` header value to provide in the request
* __path__ - the path to request from the server
* __timeout_sec__ - timeout in seconds before canceling the request (Int; default 10)

#### Matchers

##### body

Returns the String body content of the HTTP response.

    describe http_get(80, 'myhostname', '/') do
      its(:body) { should match /<html>/ }
	end

##### headers

Returns the HTTP response headers as a hash.

    describe http_get(80, 'myhostname', '/') do
      its(:headers) { should include('HeaderName' => /value regex/) }
    end

##### status

Returns the HTTP status code, or 0 if timed out.

    describe http_get(80, 'myhostname', '/') do
      its(:status) { should eq 200 }
    end

##### timed_out?

True if the request timed out, false otherwise.

    describe http_get(80, 'myhostname', '/') do
      it { should_not be_timed_out }
	end

### virtualenv

The virtualenv type has various matchers for testing the state and content of a
Python [virtualenv](https://virtualenv.pypa.io/en/latest/). It executes commands
via the builtin serverspec/specinfra command execution (i.e. uses the same backend
code that the built-in ``command`` and ``file`` types use).

    describe virtualenv('/path/to/venv') do
      # matchers here
    end

Unlike the ``http_get`` and ``bitlbee`` types, execution of the ``virtualenv`` type
commands is triggered by the matchers rather than the ``describe`` clause.

#### Parameters

* __name__ - the absolute path to the root of the virtualenv on the filesystem

#### Matchers

##### pip_freeze

Return a hash of all packages present in `pip freeze` output for the venv

Note that any editable packages (`-e something`) are returned as hash keys
with an empty value.

    describe virtualenv('/path/to/venv') do
      its(:pip_freeze) { should include('wsgiref' => '0.1.2') }
      its(:pip_freeze) { should include('requests') }
      its(:pip_freeze) { should include('pytest' => /^2\.6/) }
      its(:pip_freeze) { should include('-e git+git@github.com:jantman/someproject.git@1d8a380e3af9d081081d7ef685979200a7db4130#egg=someproject') }
    end

##### pip_version

Return the version of pip installed in the virtualenv

    describe virtualenv('/path/to/venv') do
      its(:pip_version) { should match /^6\.0\.6$/ }
    end

##### python_version

Return the version of python installed in the virtualenv

    describe virtualenv('/path/to/venv') do
      its(:python_version) { should match /^2\.7\.9$/ }
    end

##### virtualenv?

Test whether this appears to be a working venv

    describe virtualenv('/path/to/venv') do
      it { should be_virtualenv }
    end

Tests performed:

* venv_path/bin/pip executable by root?
* venv_path/bin/python executable by root?
* venv_path/bin/activate executable by root?
* 'export VIRTUAL_ENV' in venv_path/bin/activate?

## Contributing

1. Fork it ( https://github.com/jantman/serverspec-extended-types/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Testing

Spec tests are done automatically via Travis CI. They're run using Bundler and rspec.

For manual testing:

    bundle install
    bundle exec rake test

## Releasing

1. Ensure all tests are passing, coverage is acceptable, etc.
2. Increment the version number in ``lib/serverspec_extended_types/version.rb``
3. Update CHANGES.md
4. Push those changes to origin.
5. ``bundle exec rake build``
6. ``bundle exec rake release``
