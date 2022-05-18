class GenerateCsvJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
    new_file = Tempfile.new(['reporte', '.csv'])
    file = User.all.to_csv
    new_file.write(file)

    puts "============================================"
    puts "GENEREATING CSV REPORT..."
    puts new_file.inspect

    report = ExportedDataCsv.new
    report.csv_file = new_file
    report.csv_file_content_type = 'text/csv'
    
    if report.save
      puts "Report → OK"
    else
      puts "Report → Failed"
      puts report.errors.inspect unless report.errors.nil?
    end

    new_file.close
    # new_file.unlink

    puts "============================================"
  end
end
