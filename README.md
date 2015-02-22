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

    require 'rspec_matcher_hash_item'

Then use the various types that this gem provides:

### Types

@TODO: document here.

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
    bundle exec rake spec

## Releasing

1. Ensure all tests are passing, coverage is acceptable, etc.
2. Increment the version number in ``lib/serverspec_extended_types/version.rb``
3. Update CHANGES.md
4. Push those changes to origin.
5. ``bundle exec rake build``
6. ``bundle exec rake release``
