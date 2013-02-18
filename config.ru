### Make sure my own gem path is included first 
if (ENV['HOME'] =~ /^\/home\//)  ## DREAMHOST 
   ENV['GEM_HOME'] = "#{ENV['HOME']}/.gem" 
   ENV['GEM_PATH'] = "#{ENV['HOME']}/.gem/ruby/1.8:/usr/lib/ruby/gems/1.8" 
   require 'rubygems' 
   Gem.clear_paths 
else 
   # load any other paths here that don't get picked up correctly   
locally 
   require 'rubygems' 
end
require 'sinatra'
require 'sequel'

path = File.dirname(__FILE__)

set :app_file, File.join(path,'/gallery.rb')
set :root, path
set :public_folder, File.join(path, 'public')
set :run, false
set :environment, :production
set :sessions, true

set :logging, false
set :dump_errors, false

set :inline_templates, File.join(path,'/gallery.rb')

require './gallery'
run Sinatra::Application
