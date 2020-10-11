# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'openssl'

require './tapestry_login'

url = URI('https://tapestryjournal.com/login')

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

# cookie = 'tapestry_session='

# csrf_token = ''

email = ENV['EMAIL']
password = ENV['PASSWORD']

l = TapestryLogin.new(email, password)
cookie = l.get_response_cookie
csrf_token = l.csrf_token

request_body = URI.encode_www_form [
  ['email', email],
  ['_token', csrf_token],
  ['password', password],
  ['login_redirect_url', ''],
  ['login_redirect_school', ''],
  ['oauth', ''],
  ['oauth_login_url', '']
]

request = Net::HTTP::Post.new(url)
request['cookie'] = cookie
request.body = request_body

response = http.request(request)
puts '#################'
puts response['set-cookie']
puts '#################'
