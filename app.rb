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

account_sid = "AC9858c376b753a84696c9a77869dda3e3"
auth_token = "67ba2980ab6fca061075306dfeaf4556"

client = Twilio::REST::Client.new("AC9858c376b753a84696c9a77869dda3e3", "67ba2980ab6fca061075306dfeaf4556")

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
            # send the SMS from your trial Twilio number to your verified non-Twilio number
            
            client.messages.create(
            from: "+12057547035", 
            to: "+2487030094",
            body: "One new user has created an account on He@tm@ps!"
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
    @lat = results.first.coordinates[0]
    @long = results.first.coordinates[1]
    @lat_long = "#{@lat},#{@long}"
    @location = params["p"]
    @events = events_table.where(location: params["p"]).to_a

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
        results = Geocoder.search(params["location"])
        @lat = results.first.coordinates[0]
        @long = results.first.coordinates[1]
        @lat_long = "#{@lat},#{@long}"
        @events = events_table.where(location: params["location"]).to_a
        view "city_search"
    else
        view "error"
    end
end

get "/event/new" do
    @location = params["location"]
    view "create_event"
end

post "/event/create" do
    @user = users_table.where(id: session["user_id"]).to_a[0]

    events_table.insert(
        name: params["name"],
        date: params["date"],
        description: params["description"],
        user_id: session["user_id"],
        user_name: @user[:name],
        location: params["location"]
    )
    view "create_event_done"
end