require 'spec_helper'
require 'serverspec_extended_types/http_get'

describe 'http_get()' do
  context 'Serverspec::Type method' do
    it 'instantiates the class with the correct parameters' do
      expect(Serverspec::Type::Http_Get).to receive(:new).with(1, 'hostheader', 'mypath', timeout_sec=20, 'http', false)
      http_get(1, 'hostheader', 'mypath', timeout_sec=20)
    end
    it 'returns the new object' do
      expect(Serverspec::Type::Http_Get).to receive(:new).and_return("foo")
      expect(http_get(1, 'hostheader', 'mypath', timeout_sec=20)).to eq "foo"
    end
  end
  context 'initialize' do
    it 'sets instance variables' do
      expect_any_instance_of(Serverspec::Type::Http_Get).to receive(:getpage).once
      stub_const('ENV', ENV.to_hash.merge('TARGET_HOST' => 'myhost'))
      x = http_get(1, 'hostheader', 'mypath', timeout_sec=20)
      expect(x.instance_variable_get(:@ip)).to eq 'myhost'
      expect(x.instance_variable_get(:@port)).to eq 1
      expect(x.instance_variable_get(:@host)).to eq 'hostheader'
      expect(x.instance_variable_get(:@path)).to eq 'mypath'
      expect(x.instance_variable_get(:@timed_out_status)).to eq false
      expect(x.instance_variable_get(:@content_str)).to be nil
      expect(x.instance_variable_get(:@headers_hash)).to be nil
      expect(x.instance_variable_get(:@response_code_int)).to be nil
      expect(x.instance_variable_get(:@response_json)).to be nil
      expect(x.instance_variable_get(:@protocol)).to eq 'http'
      expect(x.instance_variable_get(:@bypass_ssl_verify)).to eq false
      expect(x.instance_variable_get(:@redirects)).to eq false
      expect(x.instance_variable_get(:@redirect_path)).to be nil
    end
    it 'calls getpage' do
      expect_any_instance_of(Serverspec::Type::Http_Get).to receive(:getpage).once
      x = http_get(1, 'hostheader', 'mypath', timeout_sec=20)
      expect(x.instance_variable_get(:@timed_out_status)).to eq false
    end
    it 'runs with a timeout' do
      expect(Timeout).to receive(:timeout).with(10)
      x = http_get(1, 'hostheader', 'mypath')
      expect(x.instance_variable_get(:@timed_out_status)).to eq false
    end
    it 'runs with a timeout with the specified length' do
      expect(Timeout).to receive(:timeout).with(20)
      x = http_get(1, 'hostheader', 'mypath', timeout_sec=20)
      expect(x.instance_variable_get(:@timed_out_status)).to eq false
    end
    it 'sets timed_out_status on timeout' do
      expect(Timeout).to receive(:timeout).with(20).and_raise(Timeout::Error)
      x = http_get(1, 'hostheader', 'mypath', timeout_sec=20)
      expect(x.instance_variable_get(:@timed_out_status)).to eq true
      expect(x.timed_out?).to eq true
      expect(x.status).to eq 0
    end
  end
  context '#getpage' do
    it 'requests the page' do
      stub_const('ENV', ENV.to_hash.merge('TARGET_HOST' => 'myhost'))
      conn = double
      headers = double
      expect(headers).to receive(:[]=).with(:user_agent, %r"Serverspec::Type::Http_Get/\d+\.\d+\.\d+ \(https://github.com/jantman/serverspec-extended-types\)")
      expect(conn).to receive(:headers).and_return(headers)
      expect(headers).to receive(:[]=).with(:Host, 'hostheader')
      expect(conn).to receive(:headers).and_return(headers)
      response = double
      expect(response).to receive(:status).and_return(200)
      expect(response).to receive(:body).and_return("foo bar")
      expect(response).to receive(:headers).and_return({'h1' => 'h1val', 'h2' => 'h2val'})
      expect(conn).to receive(:get).with('mypath').and_return(response)
      expect(Faraday).to receive(:new).with("http://myhost:1/").and_return(conn)
      x = http_get(1, 'hostheader', 'mypath')
      expect(x.timed_out?).to eq false
      expect(x.status).to eq 200
      expect(x.body).to eq 'foo bar'
      expected_headers = {'h1' => 'h1val', 'h2' => 'h2val'}
      expect(x.headers).to eq expected_headers
      expect(x.json).to be_empty
      expect(x.json).to be_a_kind_of(Hash)
    end
    it 'supports https' do
      # boilerplate
      stub_const('ENV', ENV.to_hash.merge('TARGET_HOST' => 'myhost'))
      headers = double
      expect(headers).to receive(:[]=).with(:user_agent, %r"Serverspec::Type::Http_Get/\d+\.\d+\.\d+ \(https://github.com/jantman/serverspec-extended-types\)")
      expect(headers).to receive(:[]=).with(:Host, 'hostheader')
      conn = double(headers: headers)
      response = double(status: 200, body: "OK", headers: [])
      expect(conn).to receive(:get).with('mypath').and_return(response)
      # most importantly, we want https here
      expect(Faraday).to receive(:new).with("https://myhost:1/").and_return(conn)
      x = http_get(1, 'hostheader', 'mypath', 30, 'https')
    end
    it 'supports ssl verify bypass for self-signed certificates' do
      # boilerplate
      stub_const('ENV', ENV.to_hash.merge('TARGET_HOST' => 'myhost'))
      headers = double
      expect(headers).to receive(:[]=).with(:user_agent, %r"Serverspec::Type::Http_Get/\d+\.\d+\.\d+ \(https://github.com/jantman/serverspec-extended-types\)")
      expect(headers).to receive(:[]=).with(:Host, 'hostheader')
      conn = double(headers: headers)
      response = double(status: 200, body: "OK", headers: [])
      expect(conn).to receive(:get).with('mypath').and_return(response)
      # most importantly, we want https here
      expect(Faraday).to receive(:new).with("https://myhost:1/", {ssl: {verify: false}}).and_return(conn)
      x = http_get(1, 'hostheader', 'mypath', 30, 'https', true)
    end
    it 'sets JSON if parsable' do
      stub_const('ENV', ENV.to_hash.merge('TARGET_HOST' => 'myhost'))
      conn = double
      headers = double
      expect(headers).to receive(:[]=).with(:user_agent, %r"Serverspec::Type::Http_Get/\d+\.\d+\.\d+ \(https://github.com/jantman/serverspec-extended-types\)")
      expect(conn).to receive(:headers).and_return(headers)
      expect(headers).to receive(:[]=).with(:Host, 'hostheader')
      expect(conn).to receive(:headers).and_return(headers)
      response = double
      expect(response).to receive(:status).and_return(200)
      expect(response).to receive(:body).and_return('{"foo": "bar", "baz": {"blam": "blarg"}}')
      expect(response).to receive(:headers).and_return({'h1' => 'h1val', 'h2' => 'h2val'})
      expect(conn).to receive(:get).with('mypath').and_return(response)
      expect(Faraday).to receive(:new).with("http://myhost:1/").and_return(conn)
      x = http_get(1, 'hostheader', 'mypath')
      expect(x.timed_out?).to eq false
      expect(x.status).to eq 200
      expect(x.body).to eq '{"foo": "bar", "baz": {"blam": "blarg"}}'
      expected_headers = {'h1' => 'h1val', 'h2' => 'h2val'}
      expect(x.headers).to eq expected_headers
      expected_json = {"foo" => "bar", "baz" => {"blam" => "blarg"}}
      expect(x.json).to eq expected_json
    end
    it 'without redirects' do
      stub_const('ENV', ENV.to_hash.merge('TARGET_HOST' => 'myhost'))

      headers = double('header')
      conn = double('conn', headers: headers)

      expect(headers).to receive(:[]=).with(:user_agent, %r"Serverspec::Type::Http_Get/\d+\.\d+\.\d+ \(https://github.com/jantman/serverspec-extended-types\)")
      expect(headers).to receive(:[]=).with(:Host, 'hostheader')

      response = double('resp', status: 200, body: 'OK', headers: ({}))

      expect(conn).to receive(:get).with('mypath').and_return(response)

      expect(Faraday).to receive(:new).with('http://myhost:1/').and_return(conn)
      x = http_get(1, 'hostheader', 'mypath')

      # test internal parameters
      expect(x.instance_variable_get(:@redirects)).to eq false
      expect(x.instance_variable_get(:@redirect_path)).to be nil

      # test exposed API
      x.should_not be_redirected
      x.should_not be_redirected_to 'https://myhost:1/mynewpath'
    end
    it 'supports redirects' do
      stub_const('ENV', ENV.to_hash.merge('TARGET_HOST' => 'myhost'))

      headers = double('header')
      conn = double('conn', headers: headers)

      expect(headers).to receive(:[]=).with(:user_agent, %r"Serverspec::Type::Http_Get/\d+\.\d+\.\d+ \(https://github.com/jantman/serverspec-extended-types\)")
      expect(headers).to receive(:[]=).with(:Host, 'hostheader')

      redirect_location = 'https://myhost:1/mynewpath'
      response = double('resp', status: 301, body: 'OK', headers: {'location' => redirect_location})

      expect(conn).to receive(:get).with('mypath').and_return(response)

      expect(Faraday).to receive(:new).with('http://myhost:1/').and_return(conn)
      x = http_get(1, 'hostheader', 'mypath')

      # test internal parameters
      expect(x.instance_variable_get(:@redirects)).to eq true
      expect(x.instance_variable_get(:@redirect_path)).to_not be nil
      expect(x.instance_variable_get(:@redirect_path)).to eq redirect_location

      # test exposed API
      x.should be_redirected
      x.should be_redirected_to redirect_location
    end
  end
end
