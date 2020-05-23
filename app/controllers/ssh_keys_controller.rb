class SshKeysController < ProtectedController
  def index
    @ssh_keys = @account.ssh_keys

    respond_to do |format|
      format.json do
        render json: @ssh_keys
      end
    end
  end

  def create
    @name = params[:ssh_key][:name]
    @key = params[:ssh_key][:key]

    @json = {}

    if @key.blank? || @name.blank?
      @json[:errors] = {}

      @json[:errors][:name] = "Please provide a key name, such as 'John\'s key'" if @name.blank?
      @json[:errors][:key] = "Key can't be blank" if @key.blank?

      respond_to do |format|
        format.json do
          render json: @json, status: :bad_request
        end
      end
      return
    end

    @new_key = @account.ssh_keys.create(name: @name, key: @key)

    respond_to do |format|
      format.json do
        render json: { message: 'Success',
                       key: {
                         id: @new_key.id,
                         name: @new_key.name
                       } }
      end
    end
  end
end
