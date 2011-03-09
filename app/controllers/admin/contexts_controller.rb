class Admin::ContextsController < AdminBaseController
  protect_from_forgery :only => [:create, :update, :delete]

  active_scaffold :context do |config|
    config.label = ""

    #config.show.link = false
    #config.delete.link = false
    #config.search.link = false



    config.update.link.label = "Edit Context"
    config.columns = [:id, :title, :filename, :download_counter]
    config.update.columns = [:title, :finished, :visible_for_public,
                             :filename,
                             :abstract, :comment, :usagerights,
                             :published, :spatialextent, :datemin, :datemax,
                             :temporalextent, :taxonomicextent, :design,
                             :dataanalysis, :circumstances]

  end
end
