require "sinatra"
require "sinatra/reloader"
require "http"
require "json"
require "sinatra/cookies"

get("/") do
  redirect "/umbrella"

end

get("/umbrella") do
  erb(:umbrella_form)
end

post("/process_umbrella") do
  @user_location = params.fetch("user_location")

  gmaps_key = ENV.fetch("GMAPS_KEY") # Set gmaps key to variable

  gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{@user_location}&key=#{gmaps_key}" # url of google geocode

  @raw_response = HTTP.get(gmaps_url).to_s

  @parsed_response = JSON.parse(@raw_response)

  results = @parsed_response.fetch("results") # Save results array into variable

  geometry = results[0]["geometry"] # Save geometry hash to variable

  location_elem = geometry["location"] # Save location hash to variable

  @lat = location_elem["lat"] # Save latitude to variable

  @lng = location_elem["lng"] # Save longitude to variable

  pirate_weather_key = ENV.fetch("PIRATE_WEATHER_KEY") # Save pirate weather key to variable

  pirate_weather_url = "https://api.pirateweather.net/forecast/#{pirate_weather_key}/#{@lat},#{@lng}" # Save weather url to variable

  weather_data = HTTP.get(pirate_weather_url) # Send request to weather api and save response to variable

  parsed_weather_data = JSON.parse(weather_data) # Parse response to JSON format

  currently_hash = parsed_weather_data.fetch("currently") # Save currently hash to variable

  @current_temp = currently_hash.fetch("temperature") # Save the current temperature to variable

  minutely = parsed_weather_data.fetch("minutely", false) # Save minutely hash to variable, or false if there isn't one

  if minutely
    @next_hour_summary = minutely.fetch("summary") 
  end

  hourly = parsed_weather_data.fetch("hourly") # Save hourly hash to variable

  hourly_data = hourly.fetch("data") # Save data hash to variable

  next_twelve_hours = hourly_data[1..12] # Create hourly range of 1 to 12

  precip_prob_limit = 0.10 # Limit to compare precipitation probability

  any_precipitation = false # Create variable for any precipitation, defaulting to false

  next_twelve_hours.each do |hour|
    precip_prob = hour.fetch("precipProbability")

    if precip_prob > precip_prob_limit # if a precipitation prob is greater than limit
      any_precipitation = true # Set precipitation variable to true

      precip_time = Time.at(hour.fetch("time")) # Save time to variable

      seconds = precip_time - Time.now # Convert time to seconds

      hours = seconds / 60 / 60 # Convert seconds to hours

    end
  end

  if any_precipitation == true # Print whether you need umbrella
    @umbrella_message = "You might want to take an umbrella!"
  else
    @umbrella_message = "You probably won't need an umbrella."
  end

  erb(:umbrella_results)
end

get("/message") do
  erb(:message_form)
end

post("/process_single_message") do

  @user_message = params.fetch("the_message")

  request_headers_hash = {
  "Authorization" => "Bearer #{ENV.fetch("OPENAI_KEY")}",
  "content-type" => "application/json"
  }

  request_body_hash = {
    "model" => "gpt-3.5-turbo",
    "messages" => [
      {
        "role" => "system",
        "content" => "You are a helpful assistant who talks like Shakespeare."
      },
      {
        "role" => "user",
        "content" => @user_message
      }
    ]
  }

  request_body_json = JSON.generate(request_body_hash)

  raw_response = HTTP.headers(request_headers_hash).post(
    "https://api.openai.com/v1/chat/completions",
    :body => request_body_json
  ).to_s

  parsed_response = JSON.parse(raw_response)

  @gpt_message = parsed_response["choices"].at(0).fetch("message").fetch("content")

  erb(:process_single_message)

end
