module Budgets
  class InvestmentsController < ApplicationController

    include FeatureFlags
    include CommentableActions
    include FlagActions

    before_action :load_current_budget
    before_action :authenticate_user!, except: [:index, :show, :json_data]

    load_and_authorize_resource :budget, except: :json_data
    load_and_authorize_resource :investment, through: :budget, class: "Budget::Investment",
                                except: :json_data

    before_action -> { flash.now[:notice] = flash[:notice].html_safe if flash[:html_safe] && flash[:notice] }
    before_action :load_ballot, only: [:index, :show]
    before_action :load_heading, only: [:index, :show]
    before_action :set_random_seed, only: :index
    before_action :load_categories, only: [:index, :new, :create, :edit, :update]
    before_action :set_default_budget_filter, only: :index
    before_action :set_view, only: :index
    before_action :load_content_blocks, only: :index
    before_action :check_params, only: :create

    skip_authorization_check only: :json_data

    feature_flag :budgets

    has_orders %w{most_voted newest oldest}, only: :show
    has_orders ->(c) { c.instance_variable_get(:@budget).investments_orders }, only: :index
    has_filters %w{not_unfeasible feasible unfeasible unselected selected}, only: [:index, :show, :suggest]

    invisible_captcha only: [:create, :update], honeypot: :subtitle, scope: :budget_investment

    helper_method :resource_model, :resource_name
    respond_to :html, :js

    def index

      @pagination_section = 15

      all_investments = if @budget.finished?
                          if params[:filter] == "unfeasible"
                            investments.unfeasible
                          else
                            investments.winners
                          end
                        else
                          if current_budget.phase == 'balloting'
                            if params[:filter] == "unfeasible"
                              investments.unfeasible
                            else
                              if params[:search].present?
                                investments
                              else
                                investments.valuation_finished_feasible
                              end
                            end
                          else
                            investments
                          end
                        end

      @all_investments_count = all_investments.count

      @investments = all_investments.page(params[:page])
                                    .per(@pagination_section)
                                    .includes(:tags, :author, :image)
                                    .for_render

      @investment_ids = @investments.ids
      @investments_map_coordinates =  MapLocation.where(investment_id: all_investments).map { |l| l.json_data }

      load_investment_votes(@investments)
      @tag_cloud = tag_cloud

      grupos = Budget::Group.where(budget_id: @budget.id)

      grupos = grupos.as_json

      grupos.each do |group|
        group['extra'] = Budget::Heading.where(group_id: group['id']).as_json
      end

      #@sectors = Budget::Group.sectores.headings.order(:name)
      @sectors = grupos
    end

    def new
      @investment.additional_images.build

      unless valid_new?
        redirect_to user_path(current_user, filter: 'budget_investments'), notice: 'Ya tienes registradas las propuestas posibles'
      end
    end

    def valid_new?

      sector = current_user.colonium.first.sector
      col_id = current_user.colonium.first.id

      # Obtener propuestas hechas por el usuario
      investments = Budget::Investment.where(budget_id: Budget.current.id, author_id: current_user.id)

      # Filtrar eliminando las partidas que ya tengan propuesta
      suburbs = Budget.current.headings.order_by_group_name_condition(sector, col_id).map do |heading|
        [heading.name_scoped_by_group, heading.id] if !investments.any?{|element| element.heading_id == heading.id}
      end

      suburbs.reject! { |c| c.blank? }

      return suburbs.count > 0;
    end

    def show
      @commentable = @investment
      @comment_tree = CommentTree.new(@commentable, params[:page], @current_order)
      @related_contents = Kaminari.paginate_array(@investment.relationed_contents).page(params[:page]).per(5)
      set_comment_flags(@comment_tree.comments)
      load_investment_votes(@investment)
      @investment_ids = [@investment.id]
    end

    def edit
      if @investment.author == current_user
        return true
      else
        redirect_to root_path,
                    notice: 'Tienes que ser el autor original del proyecto para editarlo'
      end
    end

    def update

      puts investment_params.inspect
      
      @investment.update(investment_params)
      redirect_to budget_investment_path(@budget, @investment),
                  notice: 'Se actualizo con exito.'
    end

    def create
      @investment.author = current_user

      if @investment.save
        Mailer.budget_investment_created(@investment).deliver_later
        redirect_to budget_investment_path(@budget, @investment),
                    notice: t('flash.actions.create.budget_investment')
      else
        render :new
      end
    end

    def destroy
      @investment.really_destroy!
      redirect_to user_path(current_user, filter: 'budget_investments'), notice: t('flash.actions.destroy.budget_investment')
    end

    def vote
      @investment.register_selection(current_user)
      load_investment_votes(@investment)
      respond_to do |format|
        format.html { redirect_to budget_investments_path(heading_id: @investment.heading.id) }
        format.js
      end
    end

    def suggest
      @resource_path_method = :namespaced_budget_investment_path
      @resource_relation    = resource_model.where(budget: @budget).apply_filters_and_search(@budget, params, @current_filter)
      super
    end

    def json_data
      investment =  Budget::Investment.find(params[:id])
      data = {
        investment_id: investment.id,
        investment_title: investment.title,
        budget_id: investment.budget.id
      }.to_json

      respond_to do |format|
        format.json { render json: data }
      end
    end

    private

      def load_current_budget
        @budget = Budget.find_by(id: params[:budget_id])
      end

      def resource_model
        Budget::Investment
      end

      def resource_name
        "budget_investment"
      end

      def load_investment_votes(investments)
        @investment_votes = current_user ? current_user.budget_investment_votes(investments) : {}
      end

      def set_random_seed
        if params[:order] == 'random' || params[:order].blank?
          seed = params[:random_seed] || session[:random_seed] || rand
          params[:random_seed] = seed
          session[:random_seed] = params[:random_seed]
        else
          params[:random_seed] = nil
        end
      end

      def investment_params
        params.require(:budget_investment)
              .permit(:title, :description, :heading_id, :tag_list, :ballot_offline_count,
                      :organization_name, :location, :terms_of_service, :skip_map,
                      image_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                      documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                      map_location_attributes: [:latitude, :longitude, :zoom],
                      additional_images_attributes: AdditionalImage.attribute_names.map(&:to_sym).push(:_destroy, :photo))
      end

      def load_ballot
        query = Budget::Ballot.where(user: current_user, budget: @budget)
        @ballot = @budget.balloting? ? query.first_or_create : query.first_or_initialize
      end

      def load_heading
        if params[:heading_id].present?
          @heading = @budget.headings.find(params[:heading_id])
          @assigned_heading = @ballot.try(:heading_for_group, @heading.try(:group))
          load_map
        end
      end

      def load_categories
        @categories = ActsAsTaggableOn::Tag.category.order(:name)
      end

      def load_content_blocks
        @heading_content_blocks = @heading.content_blocks.where(locale: I18n.locale) if @heading
      end

      def tag_cloud
        TagCloud.new(Budget::Investment, params[:search])
      end

      def set_view
        @view = (params[:view] == "minimal") ? "minimal" : "default"
      end

      def investments
        if @current_order == 'random'
          @investments.apply_filters_and_search(@budget, params, @current_filter)
                      .send("sort_by_#{@current_order}", params[:random_seed])
        else
          @investments.apply_filters_and_search(@budget, params, @current_filter)
                      .send("sort_by_#{@current_order}")
        end
      end

      def load_map
        @map_location = MapLocation.load_from_heading(@heading)
      end

      def check_params
        if params[:budget_investment][:heading_id].blank?
          flash.now[:error] = "Tienes que elegir a que sector pertenece"
          render :new
        elsif params[:budget_investment][:tag_list].blank?
          flash.now[:error] = "Tienes que elegir una categoría"
          render :new
        end
      end

  end
end