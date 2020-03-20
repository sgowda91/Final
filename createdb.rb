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
  String :user_id
  String :location
  String :time
end

# Insert initial (seed) data
users_table = DB.from(:events)
events_table = DB.from(:events)

users_table.insert(id: 1, 
                    name: "Ben",
                    email: "Ben@Heisawesome.com",
                    password: "getpost")

events_table.insert(name: "Spring Awakening", 
                    description: "Spring Awakening Music Festival is an annual electronic dance music festival held in Chicago.",
                    date: "03/07/2020",
                    location: "Chicago")

events_table.insert(name: "Bacon Burger Taco Fest", 
                    description: "Electric Zoo is an annual electronic music festival held over Labor Day weekend in New York City on Randall's Island.",
                    date: "09/04/2020",
                    location: "New York City")

# events_table.insert(title: "Kaleapolooza", 
#                     description: "If you're into nutrition and vitamins and stuff, this is the event for you.",
#                     date: "July 4",
#                     location: "Nowhere")

puts "Success!"