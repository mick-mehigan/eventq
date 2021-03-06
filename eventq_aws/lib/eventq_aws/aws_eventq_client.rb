require 'oj'

class AwsEventQClient
  def initialize
    @client = AwsQueueClient.new
  end

  def raise(event_type, event)

    topic_arn = @client.get_topic_arn(event_type)

    qm = QueueMessage.new
    qm.content = event
    qm.type = event_type

    message = Oj.dump(qm)

    response = @client.sns.publish({
        topic_arn: topic_arn,
        message: message,
        subject: event_type
                    })

    return response.message_id

  end

end