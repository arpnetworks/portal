class DnsRecordsController < ProtectedController
  before_action :find_dns_record, :only => [:edit, :update, :destroy]

  def reverse_dns
    @ip_blocks = @account.ip_blocks

    @records      = []
    @records_ipv6 = []
    @ip_blocks.map do |ip_block|
      ip_block_cidr_obj = ip_block.cidr_obj
      if ip_block.version == 4
        upper_bound = ip_block_cidr_obj.size - 2
        if upper_bound > 0
          ip_block_cidr_obj.range(0,
                                  ip_block_cidr_obj.size - 2,
                                  :Objectify => true).each do |ip_obj|
            dns_records = DnsRecord.where(name: ip_obj.arpa.chomp('.'))
            if !dns_records.empty?
              dns_records.each do |dns_record|
                @records << OpenStruct.new(
                  dns_record_to_hash(dns_record).merge(:ip => ip_obj.ip)
                )
              end
            end
          end
        end

        # Grab RFC 2317 delegations
        first = ip_block_cidr_obj.first.split('.')[3]
        last  = ip_block_cidr_obj.last.split('.')[3]
        dns_records_rfc2317 =
          DnsRecord.where(name: first + '-' +
                                last  + '.' +
                                ip_block_cidr_obj.arpa.chomp('.'))
        if !dns_records_rfc2317.empty?
          dns_records_rfc2317.each do |dns_record|
            @records << OpenStruct.new(
              dns_record_to_hash(dns_record)
            )
          end
        end
      end

      if ip_block.version == 6
        dns_records = DnsRecord.where(['name like ?', "%" + ip_block.cidr_obj.arpa.chomp('.')])
        if !dns_records.empty?
          dns_records.each do |dns_record|
            @records_ipv6 << OpenStruct.new(
              dns_record_to_hash(dns_record)
            )
          end
        end
      end
    end

    @records_all = @records + @records_ipv6
  end

  def new
    @dns_record = DnsRecord.new
    @dns_record.type = 'PTR'

    @domain = @account.reverse_dns_zones.first

    if @domain.nil?
      flash[:error] = "You do not have any IP blocks, why not order some? :)"
      redirect_to reverse_dns_account_dns_records_path(@account) and return
    end
  end

  def create
    empty_name = true
    if !params[:dns_record][:name].to_s.empty?
      params[:dns_record][:name] += '.'
      empty_name = false
    end

    params[:dns_record][:name] =
      params[:dns_record][:name].to_s + params[:dns_record][:domain].to_s

    @domain = params[:dns_record].delete(:domain)

    if @domain =~ /(.*).(8\.f\.2\.f\.7\.0\.6\.2\.ip6\.arpa)$/ ||
       @domain =~ /(.*).(0\.c\.2\.1\.7\.0\.a\.2\.ip6\.arpa)$/
      # There's only two domains for our entire IPv6 range
      domain_obj = DnsDomain.find_by_name($2)
    else
      domain_obj = DnsDomain.find_by_name(@domain)
    end
    domain_id = domain_obj ? domain_obj.id : nil

    @dns_record = DnsRecord.new(dns_record_params)
    @dns_record.domain_id = domain_id

    if !@account.owns_dns_record?(@dns_record) || @dns_record.domain.nil?
      @dns_record.errors.add(:name,
        "is not within your IP range")
    else
      if @dns_record.save
        flash[:notice] = "New DNS record created"
        simple_email("DNS: #{@account.display_account_name} created #{@dns_record.name} #{@dns_record.type} #{@dns_record.content}", "") rescue nil
        send_notify(@dns_record.domain.name)
        redirect_to reverse_dns_account_dns_records_path(@account) and return
      end
    end

    to_strip = "#{@domain}"
    if !empty_name
      to_strip = "\.#{to_strip}"
    end

    @dns_record[:name].sub!(/#{to_strip}$/, '')
    params[:dns_record][:name] = params[:dns_record][:name].sub(/#{to_strip}$/, '')

    render :action => 'new'
  end

  def edit
  end

  def update
    params_to_update = {
      :content => params[:dns_record][:content],
      :type    => params[:dns_record][:type]
    }

    @dns_record_temp = DnsRecord.new(@dns_record.attributes.merge(params_to_update))

    if !@account.owns_dns_record?(@dns_record_temp)
      flash.now[:error] = "Your updated record is invalid, reverting..."
      render :action => 'edit'
      return
    end

    if @dns_record.update(params_to_update)
      flash[:notice] = "Changes saved."
      simple_email("DNS: #{@account.display_account_name} updated #{@dns_record.name} #{@dns_record.type} #{@dns_record.content}", "") rescue nil
      send_notify(@dns_record.domain.name)
      redirect_to reverse_dns_account_dns_records_path(@account) and return
    end

    render :action => 'edit'
  end

  def destroy
    begin
      @dns_record.destroy
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = "There was an error deleting this record"
      flash[:error] += "<br/>"
      flash[:error] += e.message
    else
      flash[:notice] = 'DNS record was deleted.'
    end

    simple_email("DNS: #{@account.display_account_name} deleted #{@dns_record.name} #{@dns_record.type} #{@dns_record.content}", "") rescue nil
    send_notify(@dns_record.domain.name)
    redirect_to reverse_dns_account_dns_records_path(@account)
  end

  protected

  def find_dns_record
    @dns_record = DnsRecord.find(params[:id])

    # Make sure this account is allowed to modify this record
    if !@account.owns_dns_record?(@dns_record)
      flash[:error] = "You do not have permissions to edit DNS record with ID #{@dns_record.id}"
      redirect_to(reverse_dns_account_dns_records_path(@account))
    end
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not find DNS record with ID #{params[:id]}"
    redirect_to(reverse_dns_account_dns_records_path(@account))
  end

  private

  def dns_record_to_hash(dns_record)
    {
      # .id() gives us 'warning: Object#id will be deprecated; use Object#object_id'
      # so we use r_id instead
      :r_id    => dns_record.id,
      :name    => dns_record.name,
      # .type() just gives us "OpenStruct"
      # so we use r_type instead
      :r_type  => dns_record.type,
      :content => dns_record.content
    }
  end

  def send_notify(domain)
    cmd = $DNS_NOTIFY_CMD + " " + domain
    cmd_array = cmd.split(' ')
    Kernel.system(*cmd_array)
  end

  def dns_record_params
    params.require(:dns_record).permit(
      :name,
      :type,
      :content,
      :ttl
    )
  end
end
