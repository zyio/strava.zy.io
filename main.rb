require 'sinatra'
require 'strava/api/v3'
require 'json'

set :port, 4568

get '/' do
  @title = "Strava thing"
  erb :index
end

post '/results' do
  @access_token = params['access_token']
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

  @results = results.flatten.uniq

  erb :results
end
