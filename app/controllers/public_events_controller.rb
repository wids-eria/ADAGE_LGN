	class PublicEventsController < ApplicationController
	before_filter :authenticate_user!
	before_filter :get_user
	wrap_parameters format: [:json, :xml]
	protect_from_forgery except: [:create,:destroy,:show]
	respond_to :json

	def get_user
		#Find Game and user through access token
		access_token = AccessToken.where(consumer_secret: params[:access_token]).first
		errors = []
		unless access_token.nil?
		  @user = access_token.user
		else
			errors << "Invalid Access Token"
			status = 400

			respond_to do |format|
				format.json {
					render json: {errors: errors},
					status: status;
				}
			end
		end
	end

	def get_events
		events = PublicEvent.where(user_id: @user.id)

		respond_to do |format|
			format.json {
				render json: { 
					events: events.map{
						|event| {event_id: event.id}.merge(event.data)
					}
				}
			}
		end
	end

	def create
		event = PublicEvent.new(user: @user,data: params[:event])

		if event.save
		  status = 201
		else
		  @errors << "Event could not be saved"
		  status = 400
		end

		respond_to do |format|
		  format.json {
		    render json: {
		      errors: @errors
		    },
		    status: status;
		  }
		end
	end

	def destroy
		event = PublicEvent.where(id: params[:id])

		unless event.nil?
			event = event.first
			if(event.user_id == @user.id)
				if event.destroy
				  status = 201
				else
				  @errors << "Event could not be deleted"
				  status = 400
				end
			else
			  @errors << "Event could not be deleted"
			  status = 400
			end
		end

		respond_to do |format|
		  format.json {
		    render json: {
		      errors: @errors
		    },
		    status: status;
		  }
		end
	end
end