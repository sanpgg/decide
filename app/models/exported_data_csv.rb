class ExportedDataCsv < ActiveRecord::Base
  has_attached_file :csv_file
  #do_not_validate_attachment_file_type :csv_file
  validates_attachment_content_type :csv_file, content_type: ['text/plain', 'text/csv', 'application/vnd.ms-excel']
end
