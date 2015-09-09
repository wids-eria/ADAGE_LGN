class StatsController < ApplicationController
  before_filter :authenticate_user!
  wrap_parameters format: [:json, :xml]
  respond_to :json
  protect_from_forgery except: [:save_stat,:save_stats,:get_stat]

  def save_stat
    #Find Game and user through access token
    access_token = AccessToken.where(consumer_secret: params[:access_token]).first

    errors = []
    @game = nil
    unless access_token.nil?
      @game = access_token.client.implementation.game
      @user = access_token.user
    else
      errors << "Invalid Access Token"
      status = 400
    end

    unless access_token.nil? or @game.nil?
      stat = Stat.where(user_id: @user,game_id: @game).first_or_create
      #Set hstore key=>value
      stat.data[params[:key]] = params[:value]

      if stat.save
        status = 201
      else
        status = 400
      end
    end

    respond_to do |format|
      format.json {
        render json: {
          errors: errors
        },
        status: status;
      }
    end
  end

  def save_stats
    #Find Game and user through access token
    access_token = AccessToken.where(consumer_secret: params[:access_token]).first
    errors = []
    @game = nil
    unless access_token.nil?
      @game = access_token.client.implementation.game
      @user = access_token.user
    else
      errors << "Invalid Access Token"
      status = 400
    end

    unless access_token.nil? or @game.nil?
      stats = params[:stats]
      stats.keys.each do |key|

        stat = Stat.where(user_id: @user,game_id: @game).first_or_create

        #Set hstore key=>value
        stat.data[key] = stats[key]

        if stat.save
          status = 201
        else
          status = 400
        end
      end
    end

    respond_to do |format|
      format.json {
        render json: {
          errors: errors
        },
        status: status;
      }
    end
  end

  def clear_stats
    #Find Game and user through access token
    access_token = AccessToken.where(consumer_secret: params[:access_token]).first
    errors = []
    @game = nil
    unless access_token.nil?
      @game = access_token.client.implementation.game
      @user = access_token.user
    else
      errors << "Invalid Access Token"
      status = 400
    end

    unless access_token.nil? or @game.nil?
      stat = Stat.where(user_id: @user,game_id: @game).first

      stat.data = {}
      stat.save
    end

    respond_to do |format|
      format.json {
        render json: {
          errors: errors
        },
        status: status;
      }
    end
  end

  def export
    @game = Game.find(params[:id])

    authorize! :read, @game
    stats = Stat.where(game_id: @game)
    respond_to do |format|
      format.json {
        type = "text/json"

        filename = "#{@game.name} Stats.json"
        set_file_headers(filename,type)
        set_streaming_headers
        response.status = 200

        data = Hash.new
        data[:users] = Array.new
        stats.all.each do |stat|
          user_data = Hash.new
          user_data[:id] = stat.user.id
          user_data[:name] = stat.user.player_name
          user_data[:stats] = stat.data
          data[:users] << user_data
        end

        self.response_body = data.to_json

      }
      format.csv {
        type = "text/csv"

        filename = "#{@game.name} Stats.csv"
        set_file_headers(filename,type)
        set_streaming_headers
        response.status = 200

        self.response_body = Enumerator.new do |y|
          y << CSV.generate_line(["id","username","key", "value"])
        
          i=0
          stats.each do |stat|
            stat.data.keys.each do |key|
              unless key.blank?
                out = Array.new
                out << stat.user.id
                out << stat.user.player_name
                out << key
                out << stat.data[key]

                y << CSV.generate_line(out)
                i+=1
                GC.start if i%5000==0
              end
            end
          end 
        end
      }
    end
  end

  def get_stat
    #Find Game and user through access token
    access_token = AccessToken.where(consumer_secret: params[:access_token]).first

    errors = []
    @game = nil
    unless access_token.nil?
      @game = access_token.client.implementation.game
      @user = access_token.user

      if @user and params[:user]
        @user = User.find_by_player_name(params[:user])
      end
    else
      errors << "Invalid Access Token"
      status = 400
    end

    data = nil
    unless access_token.nil? or @game.nil?

      stat = Stat.where(user_id: @user,game_id: @game).first

      unless stat.nil? or stat.data[params[:key]].nil?
        data = stat.data[params[:key]]
        status = :ok
      else
        errors << ["Stat Does Not Exist For #{params[:key]}"]
        status = 400
      end
    end

    respond_to do |format|
      format.json {
        render json: {
          data: data,
          errors: errors
        },
        status: status
      }
    end
  end

  def get_stats
    #Find Game and user through access token
    access_token = AccessToken.where(consumer_secret: params[:access_token]).first

    errors = []
    @game = nil
    unless access_token.nil?
      @game = access_token.client.implementation.game
      @user = access_token.user
    else
      errors << "Invalid Access Token"
      status = 400
    end

    data = nil
    unless access_token.nil? or @game.nil?
      stat = Stat.where(user_id: @user,game_id: @game).first

      unless stat.nil?
        data = stat.data

        status = :ok
      end
    end

    respond_to do |format|
      format.json {
        render json: {
          data: data,
          errors: errors
        },
        status: status
      }
    end
  end

end