# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :events do
  primary_key :id
  foreign_key :user_id
  String :name
  String :description, text: true
  String :date
  String :location
  String :user_name
end

DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

DB.create_table! :searches do
  primary_key :id
  foreign_key :user_id
  String :location
  String :time
end

DB.create_table! :reviews do
  primary_key :id
  foreign_key :user_id
  String :location
  String :user_name
  String :favorite
  String :worst
  Integer :rating
end

# Insert initial (seed) data
users_table = DB.from(:users)
events_table = DB.from(:events)
reviews_table = DB.from(:reviews)

events_table.insert(id: 1,
                    name: "Spring Awakening", 
                    description: "Spring Awakening Music Festival is an annual electronic dance music festival held in Chicago.",
                    date: "2020-06-12",
                    user_name: "Ben",
                    location: "Chicago")

events_table.insert(id: 2,
                    name: "Electric Zoo", 
                    description: "Electric Zoo is an annual electronic music festival held over Labor Day weekend in New York City on Randall's Island.",
                    date: "2020-04-09",
                    user_name: "Ben",
                    location: "New York City")

reviews_table.insert(id: 1,
                    favorite: "They have top notch students who I love teaching!",
                    worst: "Sometimes, public transportation can be slow!",
                    user_name: "Ben",
                    location: "Chicago",
                    rating: "10")
# events_table.insert(title: "Kaleapolooza", 
#                     description: "If you're into nutrition and vitamins and stuff, this is the event for you.",
#                     date: "July 4",
#                     location: "Nowhere")

puts "Success!"