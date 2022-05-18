class VerificationController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_lock

  skip_authorization_check

  def show
    nsp = next_step_path

    redirect_to nsp[:path], notice: nsp[:notice]
  end

  private
    def next_step_path(user = current_user)

      puts "******************************************"

      if user.organization?
        puts "user.organization?"
        { path: account_path }
			elsif !user.curp? || user.ife_file_name.blank?# survey completo
        puts "!user.curp? || user.ife_file_name.blank?"
				{ path: new_residence_path }
      elsif user.level_three_verified? # survey completo
        puts "user.level_three_verified?"
        { path: account_path, notice: t('verification.redirect_notices.already_verified') }
      elsif user.level_two_verified? # direccion asignada con catastral y IFE
        puts "user.level_two_verified?"
        { path: new_survey_path } # TODO es el paso del teléfono, personalizar verificacion
      elsif user.residence_verified? && user.ife.present? #numero de registro lleno
        puts "user.residence_verified? && user.ife.present?"
        { path: new_address_user_path }
      elsif user.verification_email_sent?
        puts "user.verification_email_sent?"
        { path: verified_user_path, notice: t('verification.redirect_notices.email_already_sent') }
      elsif user.residence_verified?
        puts "user.residence_verified?"
        { path: verified_user_path }
      else
        puts "else"
        { path: new_residence_path }
      end
    end

end
