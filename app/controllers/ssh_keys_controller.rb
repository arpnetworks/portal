class SshKeysController < ProtectedController
  def index
    # TODO: Nothing to show yet
    respond_to do |format|
      format.json do
        render json: {}
      end
    end
  end

  def create
    @name = params[:ssh_key][:name]
    @key = params[:ssh_key][:key]

    if @key.blank? || @name.blank?
      respond_to do |format|
        format.json do
          render json: {
            error: "Key name and the actual key are required fields."
          }, status: :bad_request
        end
      end
      return
    end

    @account.ssh_keys.create(name: @name, key: @key)

    respond_to do |format|
      format.json { render json: { message: 'Success' } }
    end
  end
end
