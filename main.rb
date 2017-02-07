require 'sinatra'
require 'strava/api/v3'
require 'json'
require 'rest-client'

load './env.rb' if File.exists?('./env.rb')

set :environment, :production
set :port, 4568
use Rack::Session::Cookie, :key => 'rack.session', :path => '/', :secret => "#{ENV['cookie_secret']}"

get '/' do
  @title = "Strava thing"
  erb :index
end

get '/sign_in' do
  redirect "https://www.strava.com/oauth/authorize?client_id=#{ENV['oauth_client_id']}&response_type=code&redirect_uri=http://strava.zy.io/callback&approval_prompt=auto"
end

get '/sign_out' do
  session[:access_token] = nil
  redirect '/'
end

get '/callback' do
  code = params[:code]
  result = RestClient.post "https://www.strava.com/oauth/token", {client_id: "#{ENV['oauth_client_id']}", client_secret: "#{ENV['oauth_client_secret']}", code: "#{code}" }
  jresult = JSON.parse(result)
  session[:access_token] = jresult["access_token"]
  redirect '/'
end

post '/results' do
  @access_token = session[:access_token]
  @client = Strava::Api::V3::Client.new(:access_token => @access_token)

  @start_date = Date.parse(params['daterange'].split(' - ').first).to_time.to_i
  @end_date = Date.parse(params['daterange'].split(' - ').last)

  results = []
  nastybreak = ""
  (1..100).each do |i|
    page = @client.list_athlete_activities({:per_page => 200, :after => @start_date , :page => i})
    page.each do |activity|
      nastybreak = "break" if Date.parse(activity['start_date']) > @end_date
      break if nastybreak == "break"
      results << activity
    end
    break if page.empty?
    break if nastybreak == "break"
  end

  case params['runrideradio']
  when "run"
    results.delete_if{ |activity| activity['type'] != "Run"}
    @results = results.flatten.uniq
  when "ride"
    results.delete_if{ |activity| activity['type'] != "Ride"}
    @results = results.flatten.uniq
  when "both"
    @results = results.flatten.uniq
  end

  erb :results
end

