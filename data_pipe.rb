# To run this file:
# $> ruby data_pipe.rb

require 'rubygems'
require 'nokogiri' 
require 'open-uri'
require 'fileutils'

require './station_ids.rb'
require './folder_names.rb'

BASE_URL = "https://www.ndbc.noaa.gov"
output = []

def fetch_wind_direction(page)
  obs_table = page.css('table')[4].css('table')[1].css('tr')[1]
  if obs_table

    str = obs_table.css('td')[2].text
    return str[/[\d.,]+/]
  else
    nil
  end
end

def fetch_wind_speed(page)
  obs_table = page.css('table')[4].css('table')[1].css('tr')[2]
  if obs_table
    str = obs_table.css('td')[2].text
    return str[/[\d.,]+/]
  else
    nil
  end
end

def folder_path(wind_speed, wind_direction)
  return nil if wind_direction.zero?
  return nil unless wind_speed && wind_direction
  

  #figure out te right folder to put this image (some combination of wind_speed_wind_dir/filename)
  return ("data/" + WindSpeedComponent.prefix(wind_speed) + "_" + WindDirectionComponent.prefix(wind_direction) + "/")
end

def maybe_create_folder(folder_name)
  #create a new folder with the correct name if it does not exist
  FileUtils::mkdir_p(folder_name) unless Dir.exist?(folder_name)
end

# Loop through each station ID
StationIds.all_ids.each do |station_id|
  puts "starting #{station_id}"
  data_url_path = "/station_page.php?station=#{station_id}"

  # find image
  page = Nokogiri::HTML( open(BASE_URL + data_url_path) )
  
  if page.css("img[title='Click to enlarge photo']")[0]
    img_tag = page.css("img[title='Click to enlarge photo']")[0]['src']
  else
    img_tag = nil
  end
    
  next unless img_tag #skip if there is no image

  file_path = (BASE_URL + img_tag)
  file_name = file_path.split('/').last

  #find the wind speed
  wind_speed = fetch_wind_speed(page).to_f.round

  #find the wind direction
  wind_direction = fetch_wind_direction(page).to_f.round

  path = folder_path(wind_speed, wind_direction)
  
  if path

    maybe_create_folder(path)

    open(path + file_name, 'wb') do |file|
      file << open(file_path).read
    end

    puts "saved #{file_name} // Speed:#{wind_speed} Dir:#{wind_direction}"


    output << "#{path + file_name},\n"
  end
end

open('output.txt', 'a') do |file|
  file << output.join(' ')
end

