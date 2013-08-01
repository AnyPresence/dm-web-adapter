class HeffalumpsController < ApplicationController
  
  def index
    if params[:query]
      @heffalumps = [Heffalump.find(params[:query])]
    else
      @heffalumps = Heffalump.all
    end
  end
  
  def show
    @heffalump = Heffalump.find(params[:id])
  end
  
  def new
    @heffalump = Heffalump.new
  end
  
  def create
    @heffalump = Heffalump.new(heffalump_params)

    if @heffalump.save
      redirect_to @heffalump
    else
      render 'new'
    end
  end
  
  def edit
    @heffalump = Heffalump.find(params[:id])
  end
  
  def update
    @heffalump = Heffalump.find(params[:id])

    if @heffalump.update_attributes(heffalump_params)
      redirect_to @heffalump
    else
      render 'edit'
    end
  end
  
  def destroy
    @heffalump = Heffalump.find(params[:id])
    @heffalump.destroy

    redirect_to heffalumps_path
  end
  
  private
    def heffalump_params
      params.require(:heffalump).permit(:color, :num_spots, :striped)
    end
end
