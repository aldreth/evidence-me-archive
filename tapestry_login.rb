# frozen_string_literal: true

require 'dotenv/load'

require 'byebug'
require 'httparty'
require 'nokogiri'
require 'uri'

require 'net/http'
require 'openssl'

class TapestryLogin
  include HTTParty
  base_uri 'https://tapestryjournal.com'
  debug_output

  attr_reader :cookie

  def initialize(email, password)
    @email = email
    get_response = self.class.get('/')
    get_response_cookie = parse_cookies(get_response.headers['set-cookie'])
    doc = Nokogiri::HTML(get_response)
    csrf_token = doc.at('meta[name="csrf-token"]')['content']

    #     post_response = self.class.post(
    #       '/login',
    #       body: {
    #         'email': email,
    #         '_token': csrf_token,
    #         'password': password,
    #         'login_redirect_url': '',
    #         'login_redirect_school': '',
    #         'oauth': '',
    #         'oauth_login_url': ''
    #       },
    #       headers: { 'Cookie' => get_response_cookie.to_cookie_string }
    #     )
    # byebug
    # [get_response_cookie, csrf_token]
    # @cookie = post_response.headers['set-cookie']

    url = URI('https://tapestryjournal.com/login')
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

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
    @cookie = parse_cookies(response['set-cookie'])

  end

  def observations
    self.class.get('/s/scarcroft-green-nursery/observations', headers: { 'Cookie' => @cookie.to_cookie_string })
  end

  def observations?
    account_settings.include? 'Observations'
  end

  def parse_cookies(cookie)
    cookie_hash = CookieHash.new
    cookie_hash.add_cookies(cookie)
    cookie_hash
  end
end
