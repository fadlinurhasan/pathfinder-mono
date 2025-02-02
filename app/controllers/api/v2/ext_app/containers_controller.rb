class ::Api::V2::ExtApp::ContainersController < ::Api::V2::ExtApp::BaseController

  # GET /
  def index
    @cluster = ::Cluster.find_by!(name: params[:cluster_name])
    @containers = @cluster.containers.exists
    render json: ::Api::V2::ExtApp::ContainerSerializer.new(@containers).to_h
  end

  # GET /:name
  def show
    @cluster = ::Cluster.find_by!(name: params[:cluster_name])
    @container = @cluster.containers.exists.find_by(hostname: params[:hostname])
    render json: ::Api::V2::ExtApp::ContainerSerializer.new(@container).to_h
  end

  # POST /
  def create
    @cluster = ::Cluster.find_by!(name: params[:cluster_name])
    @container = Container.create_with_source!(@cluster.id, container_params)
    render json: ::Api::V2::ExtApp::ContainerSerializer.new(@container).to_h
  end

  # POST /schedule_deletion
  def schedule_deletion
    @cluster = ::Cluster.find_by!(name: params[:cluster_name])
    @container = @cluster.containers.exists.find_by(hostname: params[:hostname])
    @container.update_status('SCHEDULE_DELETION')
    render json: ::Api::V2::ExtApp::ContainerSerializer.new(@container).to_h
  end

  def reschedule
    ActiveRecord::Base.transaction do
      @cluster = ::Cluster.find_by!(name: params[:cluster_name])
      @container = @cluster.containers.exists.find_by(
        hostname: params[:hostname]
      )
      @container.update_status('SCHEDULE_DELETION')
      @new_container = @container.duplicate
      @new_container.save!
    end
    render json: ::Api::V2::ExtApp::ContainerSerializer.new(@new_container).to_h
  end

  private
    def container_params
      params.require(:container).permit(
        :hostname,
        {source: [
          :source_type,
          :mode,
          {remote: [
            :name
          ]},
          :fingerprint,
          :alias
        ]},
        {bootstrappers: [
          :bootstrap_type,
          :bootstrap_cookbooks_url,
          :bootstrap_attributes
        ]}
      )
    end
end
