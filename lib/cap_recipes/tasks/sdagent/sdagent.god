God.watch do |w|

  w.name = "sdagent"
  w.interval = 30.seconds # default
  # sd-agent doesn't appear to do a good job of ensuring only ONE of itself is started
  # added a pkill to ensure old ones that it's lost track of get killed before starting a new one.
  w.start = "/etc/init.d/sd-agent start"
  # sd-agent was failing to stop the old runners, this helps ensure a clean start
  w.stop = "pkill -f sd-agent"
  #w.restart = "/etc/init.d/sd-agent restart"
  w.pid_file = "/var/run/sd-agent/sd-agent.pid"

  FileUtils.mkdir_p File.dirname(w.pid_file)
  FileUtils.chown 'sd-agent', 'sd-agent', File.dirname(w.pid_file)

  # clean pid files before start if necessary
  w.behavior(:clean_pid_file)

  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_exits) do |c|
      c.notify = %w[ <%=god_notify_list%> ]
    end
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
      c.notify = %w[ <%=god_notify_list%> ]
    end
  end
end