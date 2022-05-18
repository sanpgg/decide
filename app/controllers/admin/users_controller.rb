class Admin::UsersController < Admin::BaseController
  load_and_authorize_resource
  skip_authorize_resource :only => [:edit, :update, :download_csv, :remove_ine_data, :generate_report, :donwloadreport]

  def index
    @users = User.by_username_email_or_document_number(params[:search]) if params[:search]
    @all_users = @users
    @users = @users.page(params[:page])

    @users_with_ine = User.where.not(ife_file_name: nil, ife_content_type: nil, ife_updated_at: nil)

    respond_to do |format|
      format.html
      format.js
      format.csv { send_data @all_users.order('created_at DESC').to_csv, filename: "usuarios-#{Date.today}.csv"}
    end
  end

  def edit
  end

  def download_csv
    if params[:new_report] == true
      #
      params.delete(:new_report) if params[:new_report]
    end
  end

  def remove_ine_data
    puts "Removing INE data..."

    users = User.where.not(ife_file_name: nil, ife_content_type: nil, ife_updated_at: nil).update_all(ife_file_name: nil, ife_content_type: nil, ife_updated_at: nil)

    redirect_to admin_users_path
  end

  def generate_report
    GenerateCsvJob.perform_now
    redirect_to(:back, notice: "Se esta generando el Reporte, espera un par de minutos y da refresh a la pagina")
  end

  def donwloadreport
    @report = ExportedDataCsv.find(params[:user_id])
    f = open("https:#{@report.csv_file.url}")
    send_file(f, :type => 'txt/csv', filename: "reporte-#{@report.id}.csv", disposition: 'attachment')
    #render :nothing => true, :status => 200, :content_type => 'text/html'
  end

  def update
    @user = User.find(params[:id])
    @colonium_id = params[:user][:colonium]
    @colonium_actual = params[:user][:colonia]
    @user_id = params[:user][:id]
    @colonia = @user.colonium.first_or_create(id: @user_id)

    sql_k = "select sector from public.colonia where id=#{@colonium_id}"
    result = ActiveRecord::Base.connection.execute(sql_k)
    sector = result.getvalue(0,0).gsub(/k/i, '')
    if sector
	sql = "update public.colonia_users set colonium_id=#{@colonium_id} where user_id=#{params[:id]}"
        ActiveRecord::Base.connection.execute(sql)
        sql_s = "update public.users set sector=#{sector} where id=#{params[:id]}"
        ActiveRecord::Base.connection.execute(sql_s)
      redirect_to admin_users_path,
                  notice: "Se actualizo Usuario con exito"
    else
      flash.now[:error] = "Ocurrio un error no se pudo actualizar"
      render :edit
    end
  end
end
