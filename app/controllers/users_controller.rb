class UsersController < ApplicationController
  respond_to :html, :json

  layout 'blank'
  before_filter :authenticate_user!, except: [:authenticate_for_token]

  def show
     @user = User.find(params[:id])
  end

  def edit
     @user = User.find(params[:id])
  end

  def update
     @user = User.find(params[:id])
     @user.attributes = params[:user]
     @user.roles.each do |role|
       @join = Assignment.where(role_id: role.id, user_id: @user.id).first
       if @join == nil
        @join = Assignment.new :assigner => current_user, :role => role, :user => @user
        @join.save
       elsif @join.assigner_id == nil
         @join.assigner_id = current_user.id
         @join.save
       end
     end
     if @user.save
       redirect_to user_path(@user)
     else
       redirect_to edit_user_path(@user)
     end
  end

  def index
    @users = User.page params[:page]
    authorize! :read, @users
    respond_to do |format|
      format.html { @users = User.page params[:page] }
      format.json { render :json => User.all }
    end
  end
  
  def stats
    @user = User.find(params[:id])
    @games = @user.data.distinct(:gameName)
    @counts = Array.new
    @names = Array.new
    @games.each_with_index do |game, i|
      game_data = @user.data.where(gameName: game)
      @names << game
      @counts << {x: i, y: game_data.distinct(:session_token).count}
    end
    puts @counts.inspect
  
  end

  def session_logs
    @user = User.find(params[:id])
    
    @session_times = @user.session_information(params[:gameName])

    @playtimes = DataGroup.new
    @playtimes.chart_js_add_to_data_group(@session_times)

    puts @playtimes.to_json
    

  end


  def context_logs
    @user = User.find(params[:id])
    @data = @user.data.asc(:timestamp)
    if params[:gameName] != nil
      @data = @data.where(gameName: params[:gameName]).asc(:timestamp)
    end

    puts 'data count: ' + @data.count.to_s

    contexts = @data.where(ada_base_types: 'ADAGEContext').asc(:timestamp)

    @context_starts = Hash.new(0)
    @context_ends = Hash.new(0)
    @context_success = Hash.new(0)
    context_stack = Array.new
    @context_list = Array.new

    
    contexts.each do |q|
      if q.ada_base_types.include?('ADAGEContextStart')
        unless context_stack.include?(q.name)
          context_stack << q.name
          @context_starts[q.name] = @context_starts[q.name] + 1 
        end
      else
        if context_stack.include?(q.name)
          context_stack = context_stack.delete(q.name)
          @context_ends[q.name] = @context_ends[q.name] + 1 
          @context_list << q.name
        end
      end
    end

    start_series = DataSeries.new 
    end_series = DataSeries.new
    count = 0
    @context_names = Array.new
    @context_starts.each do |key, value|
      start_series.data << {x: count, y: value}
      end_series.data << {x: count, y: @context_ends[key]}
      @context_names << key
      count = count + 1
    end

    @contexts = [start_series, end_series]
    puts @contexts.to_json
  
  end

  def find
    @user = User.where(player_name: params[:player_name]).first
    respond_to do |format|
      if @user.present?
        format.any { redirect_to user_path(@user) }
      else
        flash[:error] = 'Player name not found'
        format.any { redirect_to :back }
      end
    end
  end
  


  def authenticate_for_token
    @user = User.with_login(params[:email]).first
    ret = {}
    if @user != nil and @user.valid_password? params[:password]
      @auth_token = @user.authentication_token
      ret = {:session_id => 'remove me', :auth_token => @auth_token}
      respond_to do |format|
        format.json {render :json => ret, :status => :created }
        format.xml  {render :xml => ret, :status => :created }
      end
    else
      ret = {:error => "Invalid email or password"}
      respond_to do |format|
        format.json {render :json => ret, :status => :unauthorized }
        format.xml  {render :xml => ret, :status => :unauthorized }
      end
    end
  end

  def new_sequence
    @user_sequence = UserSequence.new
  end

  def create_sequence
    @user_sequence = UserSequence.new params[:user_sequence]

    if @user_sequence.valid?

      @user_sequence.create_users!

      respond_to do |format|
        format.html { redirect_to users_path }
        format.json { render :json => @user_sequence, :status => :created }
      end
    else
      respond_to do |format|
        format.html { render 'new_sequence' }
        format.json { render :json => @user_sequence }
      end
    end
  end

  def get_data
    if params[:level] != nil
      @data = AdaData.where(user_id: params[:user_id], gameName: params[:gameName], schema: params[:schema], level: params[:level], key: params[:key])
    else
      @data = AdaData.where(user_id: params[:user_id], gameName: params[:gameName], schema: params[:schema], key: params[:key])
    end
    respond_to do |format|
      format.json { render :json => @data }
    end
  end

  def data_by_game
    @user = User.find(params[:id])
    @game = Game.find_by_name(params[:gameName])
    authorize! :read, @game 
    respond_to do |format| 
      format.csv {
        out = CSV.generate do |csv|
          @user.data_to_csv(csv, @game.name)
        end
        send_data out, filename: @user.player_name+'_'+@game.name+'.csv'
      } 
      format.json { render :json => @user.data }
    end
  end

  def reset_password_form
    @user = User.new params[:user]
  end

  def reset_password
    @user = User.with_login(params[:user][:player_name]).first

    if @user.nil?
      respond_to do |format|
        format.html { flash[:alert] = "Invalid Player"; redirect_to reset_password_form_users_url }
      end
    else
      if can_change_password_for? @user
        @user.password = params[:user][:password]

        if @user.save
          respond_to do |format|
            format.html { flash[:notice] = "Password Changed!"; redirect_to reset_password_form_users_url }
          end
        else
          respond_to do |format|
            format.html { render :reset_password_form }
          end
        end
      else
        respond_to do |format|
          format.html { flash[:alert] = "Not Authorized"; redirect_to reset_password_form_users_url }
        end
      end
    end
  end

  protected

  def application
    @application ||= Client.where(app_token: params[:client_id]).first
  end

  def can_change_password_for?(user)
    json_body = {student_user_id: user.id}
    auth_response = HTTParty.get("#{Rails.configuration.password_change_authorization_server}/accounts/#{current_user.id}/can_change_password_for.json", body: json_body)
    return (auth_response.code == 200)
  end
end
