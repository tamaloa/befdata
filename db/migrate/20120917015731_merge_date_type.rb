class MergeDateType < ActiveRecord::Migration
  def self.up
    #migrate datacolumn table
    Datacolumn.where("import_data_type LIKE ?", "%date%").each do |dc|
      dc.update_attribute(:import_data_type, "date")
    end

    #sheetcells table
    Sheetcell.where(:datatype_id => 4).find_each do |cell|
        cell.update_attribute(:datatype_id, "3")
        cell.update_attribute(:import_value, MergeDateType.convert_date(cell.import_value))
        cell.update_attribute(:accepted_value, MergeDateType.convert_date(cell.accepted_value))
    end
  end

  #regenerate downloads
  Dataset.where(:download_generation_status => "finished").find_each do |dataset|
      dataset.enqueue_to_generate_download
  end

  def self.down
    #irreversible
  end

  private

  def self.convert_date(dmy)
    begin
      if dmy=~ /\.\d{2}$/
        Date.strptime(dmy,'%d.%m.%y').strftime("%Y-%m-%d")
      else
        Date.strptime(dmy,'%d.%m.%Y').strftime("%Y-%m-%d")
      end
    rescue
      dmy
    end
  end
end
