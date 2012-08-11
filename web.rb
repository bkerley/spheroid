require 'sinatra/base'
require 'sphero'
require 'haml'
require 'coffee-filter'

class Spheroid
  def self.start
    @sphero_ttys = Dir.glob('/dev/tty.Sphero*')
    @spheros = @sphero_ttys.map do |s|
      Sphero.new s rescue nil
    end.compact
  end

  def self.method_missing(name, *args)
    @spheros.each{|s| s.send name, *args}
  end

  def self.balls
    @sphero_ttys
  end
end

Spheroid.start

class SpheroidWeb < Sinatra::Base
  enable :sessions
  enable :logging

  helpers do
    def swatch(r, g, b)
      <<-EOS
      <a href='/color?r=#{r}&g=#{g}&b=#{b}' class='swatch' style='background-color: rgb(#{r}, #{g}, #{b})' target='sphero_frame'>&nbsp;</a>
      EOS
    end
  end

  get '/' do
    haml :sphero
  end

  get '/color' do
    r = params[:r].to_i
    g = params[:g].to_i
    b = params[:b].to_i

    Spheroid.rgb r, g, b
  end

  get '/drive' do
    dir = params[:dir].to_i
    speed = params[:speed].to_i

    Spheroid.roll speed, dir
  end

  post '/look_at' do
    dir = params[:dir].to_i
    dist = params[:dist].to_i

    Spheroid.roll 100, dir
    sleep dist
    Spheroid.stop
    sleep 2
    Spheroid.roll 90, ((dir + 90) % 360)
    sleep 1
    Spheroid.roll 200, ((dir + 180) % 360)
    sleep (dist/2)
    Spheroid.stop

    # redirect '/'
    ''
  end

  post '/circle' do
    speed = params[:speed].to_i

    (0..36).each do |n|
      angle = (n * 10) % 360
      Spheroid.roll speed, angle
      sleep 0.1
    end

    Spheroid.stop
    ''
  end

  post '/roll' do
    speed = params[:speed].to_i
    dir = params[:dir].to_i

    Spheroid.roll speed, dir
    # redirect '/'
    ''
  end

  post '/stop' do
    Spheroid.stop
    # redirect '/'
    ''
  end
end
