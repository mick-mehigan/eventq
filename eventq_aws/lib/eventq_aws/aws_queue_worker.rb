class AwsQueueWorker

  attr_accessor :is_running

  def initialize
    @threads = []
    @is_running = false

    @retry_exceeded_block = nil
  end

  def start(queue, options = {}, &block)
    configure(queue, options)

    puts '[QUEUE_WORKER] Listening for messages.'

    raise 'Worker is already running.' if running?

    @is_running = true
    @threads = []

    #loop through each thread count
    @thread_count.times do
      thr = Thread.new do

        client = AwsQueueClient.new
        manager = AwsQueueManager.new

        #begin the queue loop for this thread
        while true do

          #check if the worker is still allowed to run and break out of thread loop if not
          if !@is_running
            break
          end

          #get the queue
          q = manager.get_queue(queue)

          received = false
          error = false

          begin

            #request a message from the queue
            response = client.sqs.receive_message({
                queue_url: q,
                max_number_of_messages: 1,
                wait_time_seconds: 1,
                message_attribute_names: ['ApproximateReceiveCount']
                                              })

            #check that a message was received
            if response.messages.length > 0

              msg = response.messages[0]
              retry_attempts = msg.message_attributes['ApproximateReceiveCount'].to_i

              #deserialize the message payload
              message = Oj.load(msg.body)
              payload = Oj.load(message["Message"])

              puts "[QUEUE_WORKER] Message received. Retry Attempts: #{retry_attempts}"

              #begin worker block for queue message
              begin
                block.call(payload.content, payload.type, retry_attempts)

                #accept the message as processed
                client.sqs.delete_message({ queue_url: q, receipt_handle: msg.receipt_handle })
                puts '[QUEUE_WORKER] Message acknowledged.'
                received = true
              rescue => e
                puts '[QUEUE_WORKER] An unhandled error happened attempting to process a queue message.'
                puts "Error: #{e}"

                error = true
                puts '[QUEUE_WORKER] Message rejected.'

                if !queue.allow_retry
                  #remove the message from the queue so that it does not get retried
                  client.sqs.delete_message({ queue_url: q, receipt_handle: msg.receipt_handle })
                end

              end

            end

          rescue
            puts 'An error occured attempting to retrieve a message from the queue.'
          end

          #check if any message was received
          if !received && !error
            puts "[QUEUE_WORKER] No message received. Sleeping for #{@sleep} seconds"
            #no message received so sleep before attempting to pop another message from the queue
            sleep(@sleep)
          end

        end

      end
      @threads.push(thr)

    end

    if options.key?(:wait) && options[:wait] == true
      @threads.each { |thr| thr.join }
    end
  end

  def stop
    @is_running = false
    @threads.each { |thr| thr.join }
  end

  def on_retry_exceeded(&block)
    @retry_exceeded_block = block
  end

  def running?
    @is_running
  end

  private

  def configure(queue, options = {})

    @queue = queue

    #default thread count
    @thread_count = 5
    if options.key?(:thread_count)
      @thread_count = options[:thread_count]
    end

    #default sleep time in seconds
    @sleep = 15
    if options.key?(:sleep)
      @sleep = options[:sleep]
    end

  end

end