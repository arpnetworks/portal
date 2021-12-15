module Test
  class SessionsController < ApplicationController

    def show
      respond_to do |format|
        format.json do
          render json: {
            value: session[params[:id]]
          }
        end
      end
    end

    def create
      vars = params.permit(session_vars: {})
      vars[:session_vars].each do |var, value|
        session[var] = value
      end
      head :created
    end

  end
end