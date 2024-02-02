require "sinatra"
require "sinatra/reloader"
require "http"

get("/") do
  redirect "/umbrella"

end

get("/umbrella") do
  erb(:umbrella_form)
end

post("/process_umbrella") do
  @user_location = params.fetch("user_location")

  gmaps_key = ENV.fetch("GMAPS_KEY") # Set gmaps key to variable

  gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{location}&key=#{gmaps_key}" # url of google geocode

  @raw_response = HTTP.get(gmaps_url).to_s
  erb(:umbrella_results)
end
