# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "geocoder"                                                                    #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

events_table = DB.from(:events)
users_table = DB.from(:users)
searches_table = DB.from(:searches)

account_sid = "ACb012c59ad20c477e963501e9e142e254"
auth_token = "6aa0234c206c7f9ba93b41709e1f95c0"

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

get "/" do
    view "home"
end

get "/users/new" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    puts "params: #{params}"

    # if there's already a user with this email, skip!
    existing_user = users_table.where(email: params["email"]).to_a[0]
    if existing_user
        view "error"
    else
        users_table.insert(
            name: params["name"],
            email: params["email"],
            password: BCrypt::Password.create(params["password"])
        )
        redirect "/logins/new"
    end
end

get "/logins/new" do
    view "new_login"
end

post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]

    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            session["user_email"] = @user[:email]
            redirect "/"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    redirect "/logins/new"
end

get "/search/city" do
    puts "params: #{params}"

    results = Geocoder.search(params["p"])
    @lat_long = results.first.coordinates
    @location = params["p"]
    puts params["p"]

    view "city_search"
end

get "/search/saved" do
    @search = searches_table.where(user_id: session["user_id"]).to_a

    view "search_saved"
end

post "/search/save" do
    puts "params: #{params}"
    time = Time.now

    if session["user_id"]
        searches_table.insert(
            user_id: session["user_id"],
            location: params["location"],
            time: time
        )
        @search = TRUE
        @location = params["location"]
        view "city_search"
    else
        view "error"
    end
end