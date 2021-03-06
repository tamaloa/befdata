require 'test_helper'

class UploadADatasetTest < ActionDispatch::IntegrationTest
  fixtures :all

  test "upload a workbook should load metadata correctly" do
    user = User.find_by_login('nadrowski')
    post user_session_path, {:user_session => {:login => user.login, :password => "test"}}

    uploadedfile = test_file_for_upload("UnitTestSpreadsheetForUpload_new.xls")

    post create_with_datafile_datasets_path, {:datafile => {:file => uploadedfile}}
    #now it's on views/create pages
    assert_nil flash[:error]
    assert_template :create

    #test metedata/projects/ownership are loaded
    assert assigns(:dataset)
    dataset = assigns(:dataset)
    assert_instance_of(Dataset,dataset)
    assert_equal dataset.current_datafile.file_file_name, "UnitTestSpreadsheetForUpload_new.xls"


    #test metadata is correctly loaded.
    assert_equal dataset.title, "This is the title"

    #test user ownership is loaded. why dataset owners must be portal users?
    assert dataset.owners.map(&:firstname).include?("Martin")
    #test project is loaded
    assert_equal dataset.projects.map(&:shortname), ["z2 e data"]
    # import and approve process is already tested in "import_test.rb"
    #data rights is tested in "datasets_controller_test.rb"
    # reuploading a dataworkbook is tested in  "datasets_controller_test"
    dataset.current_datafile.destroy
  end
 end
