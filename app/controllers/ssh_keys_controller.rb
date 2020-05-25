class SshKeysController < ProtectedController
  before_action :find_ssh_key, only: %i[destroy]

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

  def destroy
    if @ssh_key.nil?
      respond_to do |format|
        format.json do
          render json: { errors: { message: 'Key not found' } }, status: :not_found
        end
      end
    else
      if @ssh_key.destroy
        respond_to do |format|
          format.json { render json: {} }
        end
      else
        respond_to do |format|
          format.json do
            render json: { errors: { message: 'Could not delete key' } }, status: :bad_request
          end
        end
      end
    end
  end

  protected

  def find_ssh_key
    id = params[:id]
    @ssh_key = @account.ssh_keys.find_by(id: id)
  end
end
