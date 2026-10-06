#
# Shared by the send messages on email_smtp and email: each takes the
# path to the other object as its parameter.
#

module EmailParam

  #
  # The object named by the message's parameter, if it is of the given
  # class. Otherwise report it (a syntax error if there's no parameter)
  # and return nil.
  #   type      - the class the object must be
  #   kind      - how to name that kind of object in a message
  #   example   - an example of the message, for the syntax error
  #
  def param_obj( type, kind, example )
    unless @params&.token_count&.positive?
      @engine.syntax_err "Missing the #{kind}! eg. #{example}"
      return nil
    end

    pn = @params.first
    obj = Gloo::Core::Pn.new( @engine, pn ).resolve
    if obj.nil?
      @engine.err Gloo::Core::NotFound.object( pn )
      return nil
    end

    unless obj.is_a?( type )
      @engine.err "'#{pn}' is not an #{kind}."
      return nil
    end

    return obj
  end

  #
  # Send the message with the SMTP configuration; it is true if it was
  # sent, false otherwise (with the error reported).
  #
  def send_msg( msg, config )
    sent = msg && config && Smtp.new( @engine, config ).deliver( msg )
    @engine.heap.it.set_to( sent ? true : false )
  end

end
