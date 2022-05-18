# frozen_string_literal: true

class Verification::AddressUsersController < ApplicationController
  include CustomMethods

  SPGG_CENTER_LAT = 25.6509792
  SPGG_CENTER_LONG = -100.4025976
  SPGG_MAP_ZOOM = 13

  before_action :authenticate_user!
  before_action :verify_resident! # Se está ignorando esta validación
  before_action :verify_verified! # Se está ignorando esta validación
  before_action :is_pin_selected, only: %i[create]
  before_action :set_junta_vecinal, only: %i[create]
  before_action :verify_lock, only: %i[new create]
  skip_authorization_check

  def new

    if current_user.address_user

      @address_user = current_user.address_user

      redirect_to main_app.root_url, notice: "Usuario verificado correctamente"

    elsif params[:address_user] && params[:address_user][:full_address]

      search = params[:address_user][:full_address]
      geokit_search = Geokit::Geocoders::GoogleGeocoder.geocode search
      @address_user = AddressUser.new latitude: geokit_search.latitude, longitude: geokit_search.longitude

    else

      #@address_user = AddressUser.new latitude: SPGG_CENTER_LAT, longitude: SPGG_CENTER_LONG
      @address_user = AddressUser.new latitude: 0.00, longitude: 0.00

    end

    @map_location = MapLocation.new(
      latitude: @address_user.latitude == 0.00 ? SPGG_CENTER_LAT : @address_user.latitude,
      longitude: @address_user.longitude == 0.00 ? SPGG_CENTER_LONG : @address_user.longitude,
      zoom: SPGG_MAP_ZOOM
    )
  end

  def update
    @address_user = AddressUser.find_by(id: user_address_params[:id])
    if @address_user.update(user_address_params)
      # TODO: mensajes nuevos
      # redirect_to verified_user_path, notice: t('verification.sms.create.flash.success')
      redirect_to verified_user_path
    else
      render :new
    end
  end

  def create
    @address_user = AddressUser.new(user_address_params)
    @address_user.user = current_user
    if @address_user.save
      # TODO: mensajes nuevos
      # redirect_to verified_user_path, notice: t('verification.sms.create.flash.success')
      redirect_to verified_user_path
    else
      render :new
    end
  end

  private

  def is_pin_selected
    latitude = params[:address_user_confirm][:address_user][:latitude]
    longitude = params[:address_user_confirm][:address_user][:longitude]

    if latitude.nil? || latitude.empty? || longitude.nil? || longitude.empty?
      redirect_to request.referrer, alert: "Debes seleccionar un punto en el mapa o ingresar tu dirección."
    end

    rescue
      redirect_to request.referrer, alert: "Debes seleccionar un punto en el mapa o ingresar tu dirección."
  end

  def set_junta_vecinal

    latitude = params[:address_user_confirm][:address_user][:latitude]
    longitude = params[:address_user_confirm][:address_user][:longitude]
    full_address = params[:address_user_confirm][:address_user][:full_address]

    junta_vecinal = Colonium.find_by(
      "ST_DWithin(the_geom, 'POINT(#{longitude} #{latitude})',0.0000621371)"
    )
    if junta_vecinal.nil?
      redirect_to request.referrer, alert: "No Encontramos tu dirección en el mapa, intenta de nuevo"
    else
      user = current_user
      user.colonium_ids = junta_vecinal.id
      user.save!
    end
  end

  def user_address_params
    # params.require(:address_user_confirm).permit(address_user: [:latitude, :longitude, :zoom])
    params.require(:address_user_confirm).require(:address_user).permit!
  end

  def verified_user
    return false unless params[:verified_user]
    @verified_user = VerifiedUser.by_user(current_user).where(id: params[:verified_user][:id]).first
  end

end
