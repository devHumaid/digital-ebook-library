module Api
  class EbooksController < ApplicationController
    before_action :set_ebook, only: [:show, :destroy, :download]

    # GET /api/ebooks?q=keyword&sort=title|author|recent
    def index
      ebooks = apply_sort(Ebook.search(params[:q]))
      render json: ebooks.map(&:as_json_summary), status: :ok
    end

    # GET /api/ebooks/:id
    def show
      render json: @ebook.as_json_summary, status: :ok
    end

    # POST /api/ebooks
    def create
      ebook = Ebook.new(ebook_params)

      if ebook.save
        render json: ebook.as_json_summary, status: :created
      else
        render json: { errors: ebook.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/ebooks/:id
    def destroy
      @ebook.destroy
      head :no_content
    end

    # GET /api/ebooks/:id/download
    def download
      unless @ebook.file.attached?
        return render json: { error: "No file attached" }, status: :not_found
      end

      redirect_to rails_blob_url(@ebook.file, disposition: "attachment")
    end

    # GET /api/ebooks/search?q=keyword&sort=title|author|recent
    def search
      ebooks = apply_sort(Ebook.search(params[:q]))
      render json: ebooks.map(&:as_json_summary), status: :ok
    end

    private

    def set_ebook
      @ebook = Ebook.find(params[:id])
    end

    def ebook_params
      params.permit(:title, :author, :file, :cover)
    end

    def apply_sort(scope)
      case params[:sort]
      when "title" then scope.order(title: :asc)
      when "author" then scope.order(author: :asc)
      else scope.order(created_at: :desc) # default: most recently uploaded first
      end
    end
  end
end