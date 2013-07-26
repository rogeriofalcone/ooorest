module Ooorest
  module RequestHelper
    def get_model_meta
      get_model
    end

    def to_model_name(param)
      @oe_model_name = param.gsub('-', '.')
      ooor_session.class_name_from_model_key(@oe_model_name)
    end

    def context
      @context ||= params.dup().tap do |c|
        c.delete(@model_path.gsub('-', '_')) #save/create record data not part of context
        ctx = c.delete(:context)
        c.merge(ctx) if ctx.is_a?(Hash)
        c[:active_id] = c[:id]
        %w[model_name id _method controller action format _ utf8 authenticity_token commit].each {|k| c.delete(k)}
      end
    end

    def _current_oe_credentials
      instance_eval &Ooorest.current_oe_credentials
    end

    def ooor_session
      if @ooor_session
        @ooor_session
      else
        session_credentials = _current_oe_credentials
        session_credentials.merge(params.slice(:ooor_user_id, :ooor_username, :ooor_password, :ooor_database)) #TODO dangerous?
        @ooor_session = Ooor::Base.connection_handler.retrieve_connection(session_credentials)
      end
    end

    def get_model(model_path=params[:model_name])
      if @abstract_model
        @abstract_model
      else
        @model_path = model_path
        @model_name = to_model_name(model_path)
        raise Ooorest::ModelNotFound unless (@abstract_model = ooor_session.const_get(@oe_model_name))
      end
    end

    def get_object(model=get_model, id=params[:id], fields=@fields && @fields.keys, ctx=context)
      raise Ooorest::ObjectNotFound unless (@object = model.find(id, fields: fields, context: ctx))
    end
  end
end
