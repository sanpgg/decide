class AddressUser < ActiveRecord::Base
  STATES = [
    {name: 'Aguascalientes'      , code: 'AS'},
    {name: 'Baja California'     , code: 'BC'},
    {name: 'Baja California Sur' , code: 'BS'},
    {name: 'Campeche'            , code: 'CC'},
    {name: 'Coahuila'            , code: 'CL'},
    {name: 'Colima'              , code: 'CM'},
    {name: 'Chiapas'             , code: 'CS'},
    {name: 'Chihuahua'           , code: 'CH'},
    {name: 'Ciudad de México'    , code: 'DF'},
    {name: 'Durango'             , code: 'DG'},
    {name: 'Guanajuato'          , code: 'GT'},
    {name: 'Guerrero'            , code: 'GR'},
    {name: 'Hidalgo'             , code: 'HG'},
    {name: 'Jalisco'             , code: 'JC'},
    {name: 'Estado de México'    , code: 'MC'},
    {name: 'Michoacán'           , code: 'MN'},
    {name: 'Morelos'             , code: 'MS'},
    {name: 'Mayarit'             , code: 'NT'},
    {name: 'Nuevo León'          , code: 'NL'},
    {name: 'Oaxaca'              , code: 'OC'},
    {name: 'Puebla'              , code: 'PL'},
    {name: 'Querétaro'           , code: 'QT'},
    {name: 'Quintana Roo'        , code: 'QR'},
    {name: 'San Luis Potosí'     , code: 'SP'},
    {name: 'Sinaloa'             , code: 'SL'},
    {name: 'Sonora'              , code: 'SR'},
    {name: 'Tabasco'             , code: 'TC'},
    {name: 'Tamaulipas'          , code: 'TS'},
    {name: 'Tlaxcala'            , code: 'TL'},
    {name: 'Veracruz'            , code: 'VZ'},
    {name: 'Yucatán'             , code: 'YN'},
    {name: 'Zacatecas'           , code: 'ZS'}
  ].freeze

  belongs_to :user
end
