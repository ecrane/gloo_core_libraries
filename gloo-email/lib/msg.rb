# 
# A Simple email message object
# 

class Msg

  attr_accessor :to, :from, :subject, :body
  
  # 
  # Initialize a new email message.
  # 
  def initialize( to = nil, from = nil, subject = nil, body = nil )
    @to = to
    @from = from
    @subject = subject
    @body = body
  end

  # 
  # Get the mail message to send.
  # 
  # Returns:
  #   A mail message.
  # 
  def get_mail
    mail = Mail.new
    mail.from = @from
    mail.to = @to
    mail.subject = @subject
    mail.body = @body
    return mail
  end

  # 
  # Convert the message to a string.
  # This is used for debugging and logging.
  # 
  # Returns:
  #   A string representation of the message.
  # 
  def to_s
    return "Msg(to: #{@to}, from: #{@from}, subject: #{@subject}, body: #{@body})"
  end

end
