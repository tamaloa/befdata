# This file controlls the import of an BEF-China workbook into the
# data portal.  It opens the file uploaded to the data portal and
# stores it's values in the data base.  It then goes through data and
# metadata interactively to verify the correctness of the data.  For
# opening the workbook we currently rely on the ruby-package
# "spreadsheet".  This has to be changed here to adapt to other
# formats such as Open Office or .xlsx files.

class ImportsController < ApplicationController
  before_filter :load_freeformats_dataset, :only => [:update_dataset_freeformat_file]

  skip_before_filter :deny_access_to_all
  access_control do
    #TODO this has to be specified see #
    allow logged_in

    action :update_dataset_freeformat_file do
      allow :owner, :of => :freeformats_dataset
    end
  end

  def create_dataset_freeformat
    freeformat = Freeformat.new(params[:freeformat])

    if freeformat.save
      redirect_to :controller => :datasets, :action => :upload_dataset_freeformat, :freeformat_id => freeformat.id
    else
      flash[:errors] = freeformat.errors
      redirect_to :back
    end
  end

  def update_dataset_freeformat_file
    freeformat = Freeformat.find(params[:freeformat][:id])
    freeformat.file = params[:freeformat][:file]
    if freeformat.save
      redirect_to :controller => :datasets, :action => :show, :id => freeformat.dataset.id
    else
      flash[:errors] = freeformat.errors
      redirect_to :back
    end
  
  end

  # After the general metadata of a data set has been saved to a
  # Context in the ContextsController and after the cell entries in
  # the raw data sheet have been saved in Measurement instances,
  # this method manages provenance information as
  # well as data checking and allocation to value tables
  # (Numericvalue, Categoricvalue, etc).
  def raw_data_per_header
    @dataset ||= Dataset.find(params[:dataset_id], :include => [:datacolumns, :upload_spreadsheet])
    @data_column ||= @dataset.datacolumns.select{|dc| dc.columnheader == params[:data_header]}.first

    load_workbook

    # data column specific information: start with the column header
    columnheader = @data_column.columnheader

    data_group_title = @book.method_index_for_columnheader(columnheader).blank? ? columnheader : @book.data_group_title(columnheader)
    @data_groups_available = Datagroup.find_similar_by_title(data_group_title)

    # collect all methods for the select button
    @methods_short_list = Datagroup.find(:all, :order => "title").collect{|m| [m.title, m.id]}

    # prepare a new data group instance to save it if needed
    @data_group_new = Datagroup.new(@book.methodsheet_datagroup(columnheader))

    # list of all Person Roles, sorted
    @people_list = User.find(:all, :order => :lastname)

    # Are there already people associated?
    @ppl = @data_column.users

    # Only look into the spreadsheet, if there are no people linked.
    if @ppl.blank?
      ppl = @book.lookup_data_header_people(columnheader)
      ppl = ppl.flatten.uniq
      ppl.each do |user|
        user.has_role! :responsible, @data_column
      end
      @ppl = @data_column.users
    end

    # returns a data hash with rownr => data entry from the
    # spreadsheet !Zeitschlucker?!
    #@cell_values_all = @data_column.rownr_entry_hash
    #logger.debug @cell_values_all.inspect

    # collect all categories for this data column; Array of Categories
    @portal_cats = @data_column.datagroup.datacell_categories

    @sheet_cats = @data_column.import_categories.map{|imp_c| [imp_c.category.id, imp_c.category.short, imp_c.category.long]}
  end

  def update_data_header
    data_header = Datacolumn.find(params[:datacolumn][:id])

    if data_header.update_attributes(params[:datacolumn])
      redirect_to :back
    else
      redirect_to data_path
    end
  end

  def update_data_group
    data_header = Datacolumn.find(params[:datacolumn][:id])
    data_group = Datagroup.new(params[:datagroup])

    logger.debug "--------------------------------------------------"
    logger.debug data_header.inspect
    logger.debug data_group.inspect
    logger.debug params.inspect

    begin
      Datacolumn.transaction do
        if data_group.save
          data_header.datagroup = data_group
          data_header.save
          redirect_to :back
        else
          flash[:notice] = data_group.errors
          redirect_to :back
        end
      end
    rescue ActiveRecord::RecordInvalid => invalid
      redirect_to :root
    end
  end

  # Assingning provenance informaiton: linking people to a data column
  def update_people_for_data_header
    redirect_to :back and return if params[:people].blank?
    data_column = Datacolumn.find(params[:datacolumn][:id])
    people = User.find(params[:people])

    # assigning provenance information: linking people to a data
    # column
    people.each do |pr|
      pr.has_role! :responsible, data_column
    end
    redirect_to :back
  end

  # Adding data values to data columns.  Values are imported from the
  # workbook that has been uploaded in the ContextsController.
  def add_data_values
    data_column = Datacolumn.find(params[:datacolumn][:id])
    data_column.update_attributes(params[:datacolumn])

    data_column.add_data_values()

    # by now values have been added
    if data_column.has_categories_uploaded
      redirect_to(:controller => :imports,
                  :action => :data_column_categories,
                  :data_column_id => data_column.id)
    else
      redirect_to :back
    end
  end

  def data_column_categories
    @data_column = Datacolumn.find(params[:data_column_id])
    @dataset = @data_column.dataset

    @cats_to_choose = @data_column.datagroup.datacell_categories
    @cell_uniq_arr = @data_column.invalid_values

  end

  def cell_category_create
    first_cell = Sheetcell.find(params[:sheetcell][:id])
    entry = first_cell.import_value
    same_entry_cells = first_cell.same_entry_cells

    # the new category; needs error handling
    cat = Category.new(params[:category])
    cat.comment = "manually approved"
    cat.long = entry if cat.long.blank?
    cat.description = cat.long if cat.description.blank?
    logger.debug "------------ after crating new category  ---------"
    logger.debug cat.inspect

    if cat.save
      same_entry_cells.each do |cell|
        old_cat = cell.category
        cell.update_attributes(:category => cat,
        :comment => "valid")
        old_cat.destroy # validates that it is not destroyed if
        # linked to measurement or import category
      end
      redirect_to :back
    else
      redirect_to data_path
    end
  end

  def cell_category_update
    first_cell = Sheetcell.find(params[:sheetcell][:id])
    logger.debug "- params[:measurement]  -"
    logger.debug params[:sheetecell].inspect
    first_cell.update_attributes(params[:sheetcell])
    same_entry_cells = first_cell.same_entry_cells
    logger.debug "- same_entry_cells  -"
    logger.debug same_entry_cells.inspect

    # category
    cat = first_cell.category
    cat.update_attributes(:comment => "manually approved")

    same_entry_cells.each do |cell|
      logger.debug "- old and new cell  -"
      logger.debug cell.inspect
      old_cat = cell.category
      cell.update_attributes(:category => cat,
      :comment => "valid")
      old_cat.destroy
    end

    # !! validations !!
    redirect_to :back
  end

  def dataset_freeformat_overview

    @dataset = Dataset.find(params[:dataset_id])

    if @dataset
      # nothing to be done
    else
      # really should tell them about the error
      redirect_to data_path and return
    end

  end

  def save_dataset_freeformat_tags

    @dataset = Dataset.find(params[:dataset][:id])
    @dataset.update_attributes(params[:dataset])

    redirect_to url_for(:controller => :datasets,
    :action => :show,
    :id => @dataset.id) and return
  end

  private

  def load_workbook
    @book = Dataworkbook.new(@dataset.upload_spreadsheet)
  end


  def datetime_data_column_import(data_column_id, portal_cats, sheet_cats)
    data_column = Datacolumn.find(data_column_id, :include => :sheetcells)
    date_format =
    case data_column.import_data_type
    when "date(14.07.2009)" then '%d.%m.%Y'
    when "date(2009-07-14)" then '%Y-%m-%d'
    end

    cells = data_column.sheetcells

    # Check each entry loop
    cells.each do |cell|
      entry = cell.import_value
      obs = cell.observation

      comment_cat_hash = suggest_category_for_entry(portal_cats, sheet_cats, entry)

      # invalid if not categoricvalue is found
      cell_comment = comment_cat_hash[:cell_comment]

      if cell_comment != "invalid"
        cell.category = comment_cat_hash[:cat]
      else
        begin
          entry = Date.strptime(entry, date_format)

          cell.accepted_value = entry.to_s
          cell_comment = "valid"
        rescue
          value = Category.create(:short => entry,
          :long => entry,
          :description => entry,
          :comment => "automatically generated")
          cell.category = value
        end
      end

      cell.comment = cell_comment
      cell.save
    end # Entry loop
  end

  def load_freeformats_dataset
    @freeformats_dataset = Freeformat.find(params[:freeformat][:id]).dataset
  end

end
