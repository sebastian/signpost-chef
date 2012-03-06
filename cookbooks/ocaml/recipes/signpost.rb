# --- Get signpost dependencies ---
dependency_dir = node["signpost-deps"]["installation_dir"]

directory dependency_dir do
  mode "0755"
  action :create
  recursive true
end

github_deps = [{
    :user => "avsm",
    :repos => ["re", "uri", "cohttp", "cohttpserver", "dns"]
  },{
    :user => "crotsos",
    :repos => ["openflow"]
  }]

github_deps.each do |dep|
  dep[:repos].each do |repo|
    repo_dir = "#{dependency_dir}/ocaml-#{repo}"
    git "#{dependency_dir}/ocaml-#{repo}" do
      repository "git://github.com/#{dep[:user]}/ocaml-#{repo}.git"
      reference "master"
      action :sync
      not_if "test -d #{repo_dir}"
    end

    execute "Compile and install ocaml-#{repo}" do
      command "make build && sudo make reinstall && touch installed"
      cwd repo_dir
      # Don't install if it has already been installed
      creates "#{repo_dir}/installed"
      action :run
    end
  end
end
