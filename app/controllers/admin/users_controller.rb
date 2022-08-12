class Admin::UsersController < Admin::BaseController
  load_and_authorize_resource
  skip_authorize_resource :only => [:edit, :update, :download_csv, :download_csv_v2, :import, :import_from_csv, :remove_ine_data, :generate_report, :donwloadreport, :unsubscribe_user]

  def index

    @users = User.active

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

  def download_csv_v2
    new_file = Tempfile.new(['reporte', '.csv'])
    file = User.all.to_csv
    new_file.write(file)

    f = open(new_file)
    send_file(f, :type => 'txt/csv', filename: "reporte.csv", disposition: 'attachment')
  end

  def remove_ine_data
    puts "Removing INE data..."

    users = User.where.not(ife_file_name: nil, ife_content_type: nil, ife_updated_at: nil).update_all(ife_file_name: nil, ife_content_type: nil, ife_updated_at: nil)

    redirect_to admin_users_path
  end

  def unsubscribe_user

    user = User.find(params[:user_id])

    user.erase_from_admin("Eliminado desde Admin.")

    redirect_to admin_users_path, notice: "El usuario ha sido dado de baja"
  end

  def generate_report
    GenerateCsvJob.perform_now
    redirect_to(:back, notice: "Se esta generando el Reporte, espera un par de minutos y da refresh a la pagina")
  end

  def import
  end

  def import_from_csv

    saved_users_count = 0
    error_users_count = 0

    myfile = params[:file]

    return redirect_to :back, alert: "Debes importar un archivo CSV." if myfile.nil?

    @imported_users = CSV.parse(File.read(myfile.path), headers: true)

    @imported_users.map do |user|
      user[6] = "imported_#{user[0]}"
    end

    @imported_users.each do |user|

      new_user = User.new(
        username: user[6],
        email: user[0],
        born_names: user[1],
        paternal_last_name: user[2],
        maternal_last_name: user[3],
        curp: user[4],
        phone_number: user[5]
        )

      new_user.skip_password_validation = true

      new_user.terms_of_service = '1'

      if new_user.save then
        user[7] = "Almacenado correctamente"
        saved_users_count = saved_users_count + 1
      else
        user[7] = new_user&.errors&.messages&.first
        error_users_count = error_users_count + 1
      end

    end

    @notice = "Se importaron #{saved_users_count} usuarios correctamente y #{error_users_count} con errores."

    render :import
  end

  def donwloadreport
    @report = ExportedDataCsv.find(params[:user_id])
    f = open("https:#{@report.csv_file.url}")
    send_file(f, :type => 'txt/csv', filename: "reporte-#{@report.id}.csv", disposition: 'attachment')
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
      redirect_to admin_users_path, notice: "Se actualizó el usuario con éxito"
    else
      flash.now[:error] = "Ocurrió un error al intentar actualizar"
      render :edit
    end
  end
end
