#!/usr/bin/env ruby -wKU
# AcademyVoter - By Aaron Cohen

current_path = File.dirname(__FILE__)
$LOAD_PATH << File.join(current_path, 'lib')
require 'rubygems'
require 'sinatra'
require 'YAML'
require 'uri'
require 'Pathname'
require 'votingmachine'

BALLOT_DIR = Pathname.new("./ballots/").expand_path
NOMS_FILE = Pathname.new("./nominees.yaml").expand_path

main_ballot_box = BallotBox.new(BALLOT_DIR, NOMS_FILE)

# SinatraStuff
set :port, 9494
enable :sessions

helpers do

    def base_url
        base = "http://#{Sinatra::Application.host}"
        port = Sinatra::Application.port == 80 ? base : base << ":#{Sinatra::Application.port}"
    end

    def url(path = '')
        [base_url, path].join('/')
    end
end


get '/' do
    erb :home
end

get '/vote' do
    if session.has_key?('voter_name') and session['voter_name'] != ""
        redirect "/vote/#{URI.encode(session['voter_name'])}"
    else
        erb :vote_name
    end
end

post '/vote' do
    if params.has_key?("name") and params[:name] != ""
        session['voter_name'] = params[:name]
        redirect "/vote/#{URI.encode(params[:name])}"
    else
        redirect "/vote"
    end
end

get '/vote/:voter_name' do
    ballot = main_ballot_box.get_ballot_for_name(params[:voter_name])
    category, nominees = ballot.get_next_category_and_nominees
    if category.nil?
        session[:voter_name] = ""
    end
    erb :vote, :locals => {:voter_name => params[:voter_name], :category => category, :nominees => nominees}
end

post '/vote/:voter_name' do
    if params.has_key?("voter_name") and params.has_key?("category") and params.has_key?("choice")
        ballot = main_ballot_box.get_ballot_for_name(params[:voter_name])
        ballot.vote(params[:category.to_sym], main_ballot_box.get_nominee_by_cat_and_name(params[:category.to_sym], params[:choice]))
        ballot.cast_ballot
    end

    redirect "/vote/#{URI.encode(params[:voter_name])}"
end

get '/viewresults' do
    erb :results, :locals => {:scores => main_ballot_box.get_all_scores}
end

# End Sinatra Stuff