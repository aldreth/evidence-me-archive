# frozen_string_literal: true

require 'dotenv/load'

require 'byebug'
require 'httparty'
require 'nokogiri'

BASE_URI = 'https://tapestryjournal.com/s/scarcroft-green-nursery'

class Tapestry
  include HTTParty
  base_uri BASE_URI
  # debug_output

  def initialize
    @cookie = "tapestry_session=#{ENV['COOKIE_VALUE']}"
  end

  def first_observation_id
    doc = Nokogiri::HTML(observations)
    doc.css('.media-heading a')
       .first['href']
       .match(%r{#{BASE_URI}/observation/(\d*)})
       .captures
       .first
  end

  private

  def observations
    self.class.get('/observations', headers: { 'Cookie' => @cookie })
  end
end
