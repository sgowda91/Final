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
reviews_table = DB.from(:reviews)

account_sid = ENV["TWILIO_ACCOUNT_SID"]
auth_token = ENV["TWILIO_AUTH_TOKEN"]
client = Twilio::REST::Client.new(account_sid, auth_token)

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
            # This will text my number, so be kind :). 
            client.messages.create(
            from: "+12057547035", 
            to: "+12487030094",
            body: "One new user has created an account on He@tm@p!"
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
    session["location"] = nil
    redirect "/logins/new"
end

get "/search/city/input" do
    puts "params: #{params}"
    session["location"] = params["p"]

    redirect "/search/city"
end

get "/search/city" do
    puts "params: #{params}"

    results = Geocoder.search(session["location"])

    @lat = results.first.coordinates[0]
    @long = results.first.coordinates[1]
    @lat_long = "#{@lat},#{@long}"
    @location = session["location"]
    @events = events_table.where(location: session["location"]).to_a
    @reviews = reviews_table.where(location: session["location"]).to_a
    view "city_search"
end

get "/search/saved" do
    @search = searches_table.where(user_id: session["user_id"]).to_a

    view "search_saved"
end

post "/search/save" do
    puts "params: #{params}"
    stamp = Time.now
    date = stamp.strftime("%m/%d/%Y %k:%M:%S")
    puts "Date format: #{date.class}"

    if @current_user
        searches_table.insert(
            user_id: @current_user[:id],
            location: params["location"],
            time: date
        )
    #I only included all this mess below, instead of a redirect, 
    #because I don't know how to pass the @search variable through the redirect
        @search = TRUE
        @location = params["location"]
        results = Geocoder.search(params["location"])
        @lat = results.first.coordinates[0]
        @long = results.first.coordinates[1]
        @lat_long = "#{@lat},#{@long}"
        @events = events_table.where(location: params["location"]).to_a
        @reviews = reviews_table.where(location: params["p"]).to_a
        view "city_search"
    else
        view "error"
    end
end

#displays the create event form
get "/event/new" do
    @location = params["location"]
    view "create_event"
end


#creates the event and signals event is created
post "/event/create" do
    @user = users_table.where(id: session["user_id"]).to_a[0]

    events_table.insert(
        name: params["name"],
        date: params["date"],
        description: params["description"],
        user_id: @user[:id],
        user_name: @user[:name],
        location: params["location"]
    )
    redirect "/search/city"
end
# display the event form (aka "edit")
get "/event/:id/edit" do
    puts "params: #{params}"
    @event = events_table.where(id: params["id"]).to_a[0]

    view "edit_event"
end

#update the event for new name, date, description
post "/event/:id/update" do
    puts "params: #{params}"

    # find the event to update
    @event = events_table.where(id: params["id"]).to_a[0]

    if @current_user && @current_user[:id] == @event[:user_id]
        events_table.where(id: params["id"]).update(
            name: params["name"],
            date: params["date"],
            description: params["description"]
        )
        redirect "/search/city"
    else
        view "error"
    end
end

# delete the event (aka "destroy")
get "/event/:id/destroy" do
    puts "params: #{params}"

    @event = events_table.where(id: params["id"]).to_a[0]

    if @current_user && @current_user[:id] == @event[:user_id]
        events_table.where(id: params["id"]).delete
        redirect "/search/city"
    else
        view "error"
    end
end

get "/review/new" do
    @location = session["location"]
    view "create_review"
end

post "/review/create" do
    review = reviews_table.where(location: session["location"], user_id: @current_user[:id]).to_a[0]

    if review
        view "create_review_error"
    else
        reviews_table.insert(
            rating: params["rating"],
            favorite: params["favorite"],
            worst: params["worst"],
            user_id: @current_user[:id],
            user_name: @current_user[:name],
            location: session["location"]
        )
        redirect "/search/city" 
        end
end