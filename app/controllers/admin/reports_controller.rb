class Admin::ReportsController < Admin::HeadQuartersController
  before_filter :check_access

  def services
    vps_service_code = ServiceCode.find_by_name('VPS')
    ip_block_service_code = ServiceCode.find_by_name('IP_BLOCK')
    metal_service_code = ServiceCode.find_by_name('METAL')
    backup_service_code = ServiceCode.find_by_name('BACKUP')
    thunder_service_code = ServiceCode.find_by_name('THUNDER')

    @metal_services_total = Service.active.\
      where(service_code_id: metal_service_code.id, billing_interval: 1).\
        inject(0) do |x, y|
          x + y.billing_amount.to_f
        end

    @ip_block_service_total = Service.active.\
      where(service_code_id: ip_block_service_code.id, billing_interval: 1).\
        inject(0) do |x, y|
          x + y.billing_amount.to_f
        end

    @backup_service_total = Service.active.\
      where(service_code_id: backup_service_code.id, billing_interval: 1).\
        inject(0) do|x, y|
          x + y.billing_amount.to_f
        end

    @thunder_service_total = Service.active.\
      where(service_code_id: thunder_service_code.id, billing_interval: 1).\
        inject(0) do|x, y|
          x + y.billing_amount.to_f
        end

    @vps_services_all = vps_service_code.services.not_pending.includes(:account, :service_code, :virtual_machines).order('created_at desc')
    @vps_services_deleted = vps_service_code.services.inactive.includes(:account, :service_code, :virtual_machines).order('deleted_at desc')

    @vps_service_totals = Service.give_me_totals(vps_service_code.services.\
                                                 active.where("created_at > '2009-02-28'"))

    @counts = []
    @chart_data = "".html_safe
    i = 0
    24.downto(0) do |n|
      sql = n.months.ago.strftime("%Y-%m-%%")
      @counts[i] = vps_service_code.services.not_pending.where("created_at like ?", sql).count
      @chart_data << "['".html_safe
      @chart_data << n.months.ago.strftime("%Y-%m-28")
      @chart_data << "', ".html_safe
      @chart_data << @counts[i].to_s
      @chart_data << "], "
      i += 1
    end

    @deleted_counts = []
    @deleted_chart_data = "".html_safe
    i = 0
    24.downto(0) do |n|
      sql = n.months.ago.strftime("%Y-%m-%%")
      @deleted_counts[i] = vps_service_code.services.inactive.where("deleted_at like ?", sql).count
      @deleted_chart_data << "['".html_safe
      @deleted_chart_data << n.months.ago.strftime("%Y-%m-28")
      @deleted_chart_data << "', ".html_safe
      @deleted_chart_data << @deleted_counts[i].to_s
      @deleted_chart_data << "], "
      i += 1
    end

    @metal_services_all = metal_service_code.services.includes(:account, :service_code).order("created_at desc")

    @metal_services_deleted = metal_service_code.services.inactive.includes(:account, :service_code).order("deleted_at desc")

    @metal_service_totals = Service.give_me_totals(metal_service_code.services.active)

    @metal_counts = []
    @metal_chart_data = "".html_safe
    i = 0
    24.downto(0) do |n|
      sql = n.months.ago.strftime("%Y-%m-%%")
      @metal_counts[i] = metal_service_code.services.where("created_at like ?", sql).count
      @metal_chart_data << "['".html_safe
      @metal_chart_data << n.months.ago.strftime("%Y-%m-28")
      @metal_chart_data << "', ".html_safe
      @metal_chart_data << @metal_counts[i].to_s
      @metal_chart_data << "], "
      i += 1
    end

    @metal_deleted_counts = []
    @metal_deleted_chart_data = "".html_safe
    i = 0
    24.downto(0) do |n|
      sql = n.months.ago.strftime("%Y-%m-%%")
      @metal_deleted_counts[i] = metal_service_code.services.inactive.where("deleted_at like ?", sql).count
      @metal_deleted_chart_data << "['".html_safe
      @metal_deleted_chart_data << n.months.ago.strftime("%Y-%m-28")
      @metal_deleted_chart_data << "', ".html_safe
      @metal_deleted_chart_data << @metal_deleted_counts[i].to_s
      @metal_deleted_chart_data << "], "
      i += 1
    end

    @mrc_counts = []
    @mrc_chart_data = "".html_safe
    i = 0
    36.downto(0) do |n|
      sql = n.months.ago.strftime("%Y-%m-%%")
      @mrc_counts[i] = Service.where("created_at <= ? and (deleted_at > ? or deleted_at is null)", sql, sql).\
        inject(0) do |x, y|
          (y.billing_interval == 1 ? y.billing_amount.to_f : 0) + x
        end
      @mrc_chart_data << "['".html_safe
      @mrc_chart_data << n.months.ago.strftime("%Y-%m-28")
      @mrc_chart_data << "', ".html_safe
      @mrc_chart_data << @mrc_counts[i].to_s
      @mrc_chart_data << "], ".html_safe
      i += 1
    end

    @metal_mrc_counts = []
    @metal_mrc_chart_data = "".html_safe
    i = 0
    36.downto(0) do |n|
      sql = n.months.ago.strftime("%Y-%m-%%")
      @metal_mrc_counts[i] = metal_service_code.services.where("created_at <= ? and (deleted_at > ? or deleted_at is null)", sql, sql).\
        inject(0) do |x, y|
          (y.billing_interval == 1 ? y.billing_amount.to_f : 0) + x
        end
      @metal_mrc_chart_data << "['".html_safe
      @metal_mrc_chart_data << n.months.ago.strftime("%Y-%m-28")
      @metal_mrc_chart_data << "', ".html_safe
      @metal_mrc_chart_data << @metal_mrc_counts[i].to_s
      @metal_mrc_chart_data << "], ".html_safe
      i += 1
    end

    @thunder_mrc_counts = []
    @thunder_mrc_chart_data = "".html_safe
    i = 0
    36.downto(0) do |n|
      sql = n.months.ago.strftime("%Y-%m-%%")
      @thunder_mrc_counts[i] = thunder_service_code.services.where("created_at <= ? and (deleted_at > ? or deleted_at is null)", sql, sql).\
        inject(0) do |x, y|
          (y.billing_interval == 1 ? y.billing_amount.to_f : 0) + x
        end
      @thunder_mrc_chart_data << "['".html_safe
      @thunder_mrc_chart_data << n.months.ago.strftime("%Y-%m-28")
      @thunder_mrc_chart_data << "', ".html_safe
      @thunder_mrc_chart_data << @thunder_mrc_counts[i].to_s
      @thunder_mrc_chart_data << "], ".html_safe
      i += 1
    end

    @vps_mrc_counts = []
    @vps_mrc_chart_data = "".html_safe
    i = 0
    36.downto(0) do |n|
      sql = n.months.ago.strftime("%Y-%m-%%")
      @vps_mrc_counts[i] = vps_service_code.services.not_pending.where("created_at <= ? and (deleted_at > ? or deleted_at is null)", sql, sql).\
        inject(0) do |x, y|
          (y.billing_interval == 1 ? y.billing_amount.to_f : 0) + x
        end
      @vps_mrc_chart_data << "['".html_safe
      @vps_mrc_chart_data << n.months.ago.strftime("%Y-%m-28")
      @vps_mrc_chart_data << "', ".html_safe
      @vps_mrc_chart_data << @vps_mrc_counts[i].to_s
      @vps_mrc_chart_data << "], ".html_safe
      i += 1
    end

    @mrc_total = Service.active.inject(0) do |sum,service|
      (service.billing_interval == 1 ? service.billing_amount : 0) + sum
    end
  end

  def check_access
    unless @is_super_admin
      redirect_to admin_path
    end
  end
end
