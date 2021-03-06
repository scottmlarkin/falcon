# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'falcon/server'
require 'async/http/client'
require 'async/rspec/reactor'

require 'rack'

RSpec.describe Falcon::Server do
	include_context Falcon::Server
	
	context "http client" do
		let(:app) do
			lambda do |env|
				request = Rack::Request.new(env)
				
				if request.post?
					[200, {}, ["POST: #{request.POST.inspect}"]]
				else
					[200, {}, ["Hello World"]]
				end
			end
		end
		
		context "GET /" do
			let(:response) {client.get("/")}
			
			it "generates successful response" do
				expect(response).to be_success
				expect(response.read).to be == "Hello World"
			end
			
			it "generates server and date headers" do
				expect(response.headers).to include('date', 'server')
				
				expect(response.headers['server'].join).to include("falcon")
			end
		end
		
		it "can POST application/x-www-form-urlencoded" do
			response = client.post("/", {'content-type' => 'application/x-www-form-urlencoded'}, ['hello=world'])
			
			expect(response).to be_success
			expect(response.read).to be == 'POST: {"hello"=>"world"}'
		end
		
		it "can POST multipart/form-data" do
			response = client.post("/", {'content-type' => 'multipart/form-data; boundary=multipart'}, ["--multipart\r\n", "Content-Disposition: form-data; name=\"hello\"\r\n\r\n", "world\r\n", "--multipart--"])
			
			expect(response).to be_success
			expect(response.read).to be == 'POST: {"hello"=>"world"}'
		end
	end
	
	context "broken middleware" do
		let(:app) do
			lambda do |env|
				raise RuntimeError, "Middleware is broken"
			end
		end
		
		it "results in a 500 error if middleware raises an exception" do
			response = client.get("/", {})
			
			expect(response).to_not be_success
			expect(response.status).to be == 500
			expect(response.read).to be =~ /RuntimeError: Middleware is broken/
		end
	end
end
