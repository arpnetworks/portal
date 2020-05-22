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
    @account
  end
end
