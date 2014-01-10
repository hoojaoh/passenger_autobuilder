require 'json'
require 'yaml'
require 'logger'

LOGGER = Logger.new(STDOUT)

def is_master_commit_push?(payload)
  payload["ref"] == "refs/heads/master"
end

def is_tag_push?(payload)
  payload["ref"] && payload["ref"] =~ /^refs\/tags\// && payload["created"]
end

def extract_tag_name(payload)
  payload["ref"].sub(/^refs\/tags\//, '')
end

def find_project(payload)
  repo_name = payload["repository"]["name"]
  projects = YAML.load_file("projects.yml")
  projects[repo_name]
end

def schedule_build(project, tag_name = nil)
  command = "/tools/silence-unless-failed -f /tmp/passenger_autobuilder.log " +
    "chpst -l /var/cache/passenger_ci/lock " +
    "./autobuild-with-pbuilder #{project['git_url']} #{project['name']}"
  if tag_name
    command << " --tag=#{tag_name}"
  end
  log "Executing command: #{command}"
  IO.popen("at now", "w") do |f|
    f.puts("cd /srv/passenger_autobuilder/app")
    f.puts(command)
  end
  true
end

def process_request(request, payload)
  if is_master_commit_push?(payload)
    if project = find_project(payload)
      schedule_build(project)
    else
      log "Cannot find project"
      false
    end
  elsif is_tag_push?(payload) && (tag_name = extract_tag_name(payload))
    if project = find_project(payload)
      schedule_build(project, tag_name)
    else
      log "Cannot find project"
      false
    end
  else
    log "Unrecognized request"
    false
  end
end

def log(message)
  LOGGER.info "[passenger_autobuilder webhook] #{message}"
end

app = lambda do |env|
  request = Rack::Request.new(env)
  if !(payload = request.params["payload"])
    payload = env['rack.input'].read
  end
  if process_request(request, JSON.parse(payload))
    [200, { "Content-Type" => "text/plain" }, ["ok"]]
  else
    [500, { "Content-Type" => "text/plain" }, ["Internal server error"]]
  end
end

run app
