#! /usr/bin/env ruby

require 'rubygems'
require 'pp'
require 'socket'
require 'fileutils'

def ask_yes_no question
  response=nil
  while (response != "n" and response != "N" and
      response != "y" and response != "Y") do

    print  "#{question} [yN] "
    response = gets.chomp
    break unless response == ""
  end

  # if we have seen an "n", "N" or a blank response (defaults to N),
  # we exit here
  not (response == "n" or response == "N" or response == "")
end

# Function to ask the user whether he/she would like to continue.
# Valid responses are "Y", "y", "N" and "n".
def ask_continue
  exit 1 unless ask_yes_no "Do you want to continue?"
end

def error_colour 
  col_err="\x1b[1;31m"
  print col_err
end

def blue_colour
  col_blue="\x1b[34;01m"
  print col_blue
end

def yellow_colour 
  col_yellow="\x1b[1;33m"
  print col_yellow
end

def reset_colour 
  col_reset="\x1b[39;49;00m"
  print col_reset
end

def welcome
  puts "Welcome to the signpost client setup wizard."
  puts "Have you already set up your signpost server?"
  puts "If not, please do so first."
  puts ""
  unless ask_yes_no "I have already set up my signpost server" then
    puts ""
    puts "Ok, let's setup your signpost server first."
    puts ""
    exec("curl -s https://raw.github.com/sebastian/signpost-chef/master/deploy-server.sh > /tmp/sp-install.sh && bash /tmp/sp-install.sh; rm /tmp/sp-install.sh")
    exit 0
  end
  puts ""
  puts "In order to setup the signpost client, you need to have the OCaml toolchain installed."
  puts "More specifically, you need:"
  puts
  puts "* OCaml"
  puts "* findlib"
  puts "* iodine"
  puts
  unless ask_yes_no "I meet these requirements" then
    puts "Please go ahead an install the required software first."
    puts "Afterwards, please run this installer again."
    puts
    puts "OCaml and findlib:"
    blue_colour
    puts "curl -kL https://raw.github.com/hcarty/ocamlbrew/master/ocamlbrew-install | bash"
    reset_colour
    puts
    puts "Iodine:"
    blue_colour
    puts "If you are on a mac, try 'brew install iodine'"
    reset_colour
    exit 0
  end
end

def request_with_default what, description, default = ""
  while true do
    puts description
    yellow_colour
    print "#{what} "
    reset_colour
    if default != "" then
      print "(defaults to '#{default}')"
    else
      print "[required]"
    end
    print ": "
    response = gets.chomp

    if response =~ / / then
      error_colour
      puts "#{what} cannot contain spaces"
      reset_colour
    else
      if response != "" then
        return response
      else
        if default != "" then
          return default
        end
      end
    end
  end
end

@@domain = "d2.signpo.st"
@@iodine_password = ""

def get_info
  domain_default = "d2.signpo.st"
  paras = {}

  blue_colour
  puts ""
  puts "Signpost server information"
  reset_colour
  puts "In order to setup your client, we will need the following information."
  paras[:domain] = request_with_default "domain", "Your domain name. The one you are using for your signpost. It is probably of the form 'd2.signpo.st'", domain_default

  puts ""
  paras[:password] = request_with_default "password", "This is the password you set when setting up your signpost server."

  return paras
end

def connect_with_iodine paras
  puts "--> attemting autodiscovery of settings"
  puts ""
  if (`ps -e | grep iodine | wc -l `).to_i > 1 then
    error_colour
    puts "Warning:"
    reset_colour
    puts "If you choose to continue, your currently running instances of iodine will be terminated."
    ask_continue  
    puts "--> terminating existing iodine daemons"
    `sudo killall iodine`
  end
  puts "--> attempting auto discovery of settings"
  puts "--> attempting to establish contact with #{paras[:domain]}"
  `sudo iodine -P #{paras[:password]} i.#{paras[:domain]} > iodine_info 2> iodine_info`
  iodine_setup_output = `grep "Bad password" iodine_info`
  `rm iodine_info`
  if iodine_setup_output =~ /Bad password/ then
    error_colour
    puts "ERROR: The password provided is incorrect."
    reset_colour
    exit 1
  end
  print "--> discovering settings"
  get_config
end

def get_config
  cmd = <<-eos
  if [ "`ifconfig | grep -E "^tun0" | wc -l`" -gt 0 ]; then
      IP=`ifconfig tun0 |grep 172.16 | awk '{print $2}'`;
  else
      if [ "`ifconfig | grep dns0 | wc -l`" -gt 0 ]; then 
          IP=`ifconfig dns0 |grep 172.16 | tr \: \  | awk '{print $3}'`;
      else
          echo "no valid network interface found"
          # exit 1
      fi
  fi
  echo $IP
  eos

  # Make an RPC to the server to detect the settings we are supposed to use
  ip = (`#{cmd}`).chomp
  listen_port = 5943
  msg = {
    :request => {
      :method => "config_discovery",
      :params => [ip, listen_port],
      :id => 1
    }
  }
  msg_json = msg.to_json
  server_ip = "172.16.11.1"
  server_port = 3456

  socket = UDPSocket.new
  socket.bind("0.0.0.0", listen_port)

  socket.send msg_json, 0, server_ip, server_port

  retry_count = 100
  sleep(0.1)
  begin # emulate blocking recvfrom
    while retry_count > 0 do
      data, addr = socket.recvfrom_nonblock(100000)  #=> ["aaa", ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
      puts ""
      return JSON.parse(data)["response"]["result"]
    end
  rescue Exception => e
    if retry_count > 0 then
      print "." if retry_count % 10 == 0
      retry_count -= 1
      sleep(0.1)
      retry
    end
  end
  error_colour
  puts ""
  puts "Failed at discovering settings from the server. Are you sure the signpost server is running?"
  reset_colour
  exit 1
end

def check_for src
  cmd = <<-eos
  src="#{src}"
  whereis=`whereis #{src}`;
  if [[ $whereis == "" ]]; then
    echo "$src"
  fi
  eos
  unless `#{cmd}` == "" then
    error_colour
    puts "Missing dependency"
    reset_colour
    puts "Please install '#{src}'. Afterwars rerun this script."
    exit 1
  end
end

def check_deps
  check_for "git"
end

def get_and_build github_user, project, prebuild_callback, install = true
  working_dir = File.expand_path("~/signpost/sources")

  puts "--> get #{project} source"
  dst = "#{working_dir}/#{project}"
  `(git clone https://github.com/#{github_user}/#{project}.git #{dst}) > /dev/null 2> /dev/null`

  # Run callback
  prebuild_callback.call

  # Build and install
  if install then
    puts "--> building and installing #{project}"
  else
    puts "--> building #{project}"
  end

  build = if install then
    <<-eoc
    make build &&
    sudo make reinstall
    eoc
  else
    <<-eoc
    make build
    eoc
  end

  cmd = <<-eoc
    (cd #{working_dir}/#{project} &&
    #{build}) > /dev/null 2> /dev/null
  eoc
  `#{cmd}`
end

def get_dependencies
  working_dir = File.expand_path("~/signpost/sources")
  if File.exists? working_dir then
    FileUtils.rm_rf working_dir
  end
  FileUtils.mkdir_p "#{working_dir}"

  deps = [{
    :user => "avsm",
    :projects => [
      "ocaml-re", 
      "ocaml-uri", 
      "ocaml-cohttp",
      "ocaml-cohttpserver",
      "ocaml-dns"
    ]
  },{
    :user => "crotsos",
    :projects => [
      "ocaml-openflow"
    ]
  }]
 
  null_callback = Proc.new {}
  
  deps.each do |dep|
    dep[:projects].each do |project|
      get_and_build dep[:user], project, null_callback
    end
  end
end

def make_signpost config, paras
  callback = Proc.new {
    config_ml = <<-eof
(*
 * Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

let user = "#{config["user"]}"
let signpost_number = #{config["signpost_number"]}
let domain = "#{config["domain"]}"
let ip_slash_24 = "172.16.11."
let external_ip = "#{config["external_ip"]}"
let external_dns = "#{config["external_dns"]}"
let dir = "/home/cr409/scratch/code/signpostd/"
let iodine_node_ip = "172.16.11.1"
let ns_server="8.8.8.8"
let signal_port = 3456
(* RPCs timeout after 5 minutes *)
let rpc_timeout = 5 * 60
    eof
    signpost_src = File.expand_path("~/signpost/sources/signpostd")
    File.open("#{signpost_src}/lib/config.ml", "w") do |f|
      f.puts config_ml
    end
    File.open("#{signpost_src}/scripts/PASSWD", "w") do |f|
      f.puts paras[:password]
    end
  }

  get_and_build "avsm", "signpostd", callback, false
end

def install_json_gem
  puts "--> installing json rubygem"
  `sudo gem install json`
  require 'json'
end

puts `clear`
check_deps

paras = {}
if ARGV.size == 2 then
  paras[:password] = ARGV.shift
  paras[:domain] = ARGV.shift
  blue_colour
  puts "Will shortly resume the installation of the client software"
  sleep(2)
  reset_colour
  puts "--> resuming client installation"
else
  welcome
  paras = get_info
end

error_colour
puts "Warning:"
reset_colour
puts "You will also be asked for your sudo password, unless you have passwordless sudo enabled."

install_json_gem
config = connect_with_iodine paras
get_dependencies
make_signpost config, paras

puts ""
puts "Congratulations. You can now run your signpost with the following command:"
blue_colour
signpost_src = File.expand_path("~/signpost/sources/signpostd")
puts "cd #{signpost_src} && sudo ./scripts/run-client"
reset_colour
