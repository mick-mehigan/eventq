class AwsQueueManager

  @@dead_letter_queue = 'dead_letter_archive'

  def initialize
    @client = AwsQueueClient.new
  end

  def get_queue(queue)

    response = @client.sqs.create_queue({
        queue_name: queue.name,
        attributes: {
            'VisibilityTimeout' => (queue.retry_delay / 1000).to_s
        }
                         })

    return response.queue_url

  end

  def drop_queue(queue)

    q = get_queue(queue)

    @client.sqs.delete_queue({ queue_url: q})

  end

  def drop_topic(event_type)
    topic_arn = @client.get_topic_arn(event_type)
    @client.sns.delete_topic({ topic_arn: topic_arn})
  end

end