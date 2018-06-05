require_relative 'session.rb'

require 'fileutils'
require 'io/console'

BASEPATH = "out"

CIO.puts "Username:"
user = gets.chomp

CIO.puts "Password:"
pass = STDIN.noecho(&:gets).chomp

session = BBSession.new user, pass

# Fetch Units
CIO.puts
session.fetchUnits

# Discover Unit Sidebar Listings
CIO.puts
session.units.values.each(&:discover)

# Crawl Unit Listings (recursively enter listings)
CIO.puts
session.units.values.each(&:crawl)

# Report Status
CIO.puts
CIO.puts "Unit Report: "
CIO.with do 
    session.units.values.each do |unit|
        CIO.puts "#{unit.to_s}:"
        CIO.with do
            unit.listings.values.each do |listing|
                CIO.puts "#{listing.to_s}"
                CIO.with do
                    CIO.puts "(#{listing.collectAssets.values.size} asset(s))"
                end
            end
        end
    end
end

# Download Assets
CIO.puts
CIO.puts "Downloading Assets..."
CIO.with do 
    assets = session.units.values.map(&:collectAssets).map(&:values).flatten
    asset_count = assets.size
    assets.each_with_index do |asset, i|
        CIO.puts "Downloading asset (#{i}/#{asset_count}): #{asset.to_s}"
        asset.download BASEPATH
    end
end