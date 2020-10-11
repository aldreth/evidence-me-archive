# frozen_string_literal: true

require 'dotenv/load'

require 'byebug'
require 'httparty'
require 'nokogiri'

OBSERVATION_URL = 'https://tapestryjournal.com/s/scarcroft-green-nursery/observation'

class TapestryObservation
  include HTTParty
  base_uri OBSERVATION_URL
  debug_output

  def initialize(id)
    @cookie = "tapestry_session=#{ENV['COOKIE_VALUE']}"
    @id = id
  end

  def observation
    # TODO: Should save all the images & videos
    save_images
    { title: title, subtitle: subtitle, body: body, reporter: reporter, date: date }
  end

  private

  def doc
    @doc ||= Nokogiri::HTML(response)
  end

  def response
    @response ||= self.class.get("/#{@id}", headers: { 'Cookie' => @cookie })
  end

  def title
    byebug
    @title ||= doc.css('h1').first?.text?.strip || 'Default title'
  end

  def subtitle
    @subtitle ||= "#{reporter}, #{date.strftime('%-d %B %Y %l:%M%P')}"
  end

  def body
    @body ||= doc.css('.page-note p').text.strip.gsub(/\s+/, ' ')
  end

  def date_and_reporter
    @date_and_reporter ||= begin
      doc.css('.obs-metadata p').first.text.strip.match(/Authored by (.*) added (.*)/)
      reporter = Regexp.last_match(1)
      date = DateTime.parse(Regexp.last_match(2))
      [date, reporter]
    end
  end

  def date
    date_and_reporter.first
  end

  def reporter
    date_and_reporter.last
  end

  def images
    doc.css('.obs-media-gallery-main img')
  end

  def videos
    doc.css('.obs-media-gallery-main .obs-video-wrapper video source')
  end

  def base_file_name
    @base_file_name ||= begin
      file_name = date.strftime('./images/%Y-%m-%d-%H-%M-')
      file_name += title
                   .downcase
                   .delete("^\u{0000}-\u{007F}")
                   .strip
                   .squeeze(' ')
                   .gsub(' ', '-')
      file_name
    end
  end

  def get_file_name(index, video = false)
    file_name = base_file_name
    file_name += "-#{index}" if index.positive?
    file_name += video ? '.mp4' : '.jpeg'
    file_name
  end

  def save_images
    images.each_with_index do |img, idx|
      image_url = img.attribute('src').value
      image = HTTParty.get(image_url)

      file_name = get_file_name(idx)
      File.write(file_name, image)
      # set_metadata_for_image(file_name: file_name, metadata: metadata)
    end
  end
end
