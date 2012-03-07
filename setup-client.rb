#! /usr/bin/env ruby

require 'pp'
require 'socket'
require 'json/ext'

def ask_yes_no question
  # TODO: Remove auto
  return true
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
    puts "Please run the following command, before running this wizard again:\n"
    blue_colour
    puts "curl -s https://raw.github.com/sebastian/signpost-chef/master/deploy-server.sh > /tmp/sp-install.sh && bash /tmp/sp-install.sh; rm /tmp/sp-install.sh"
    reset_colour
    puts
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
  # TODO: Remove default
  return {:domain => "d2.signpo.st", :password => "foobar"}

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
  puts ""
  puts "--> attemting autodiscovery of settings"
  puts ""
  error_colour
  puts "Warning:"
  reset_colour
  puts "You will also be asked for your sudo password, unless you have passwordless sudo enabled."
  if (`ps -e | grep iodine | wc -l `).to_i > 1 then
    puts "If you choose to continue, your currently running instances of iodine will be terminated."
    ask_continue  
    puts "--> terminating existing iodine daemons"
    `sudo killall iodine`
  end
  puts "--> attempting auto discovery of settings"
  puts "--> attempting to establish contact with #{paras[:domain]}"
  `sudo iodine -P #{paras[:password]} 192.168.56.101 i.#{paras[:domain]} > iodine_info 2> iodine_info`
  iodine_setup_output = `grep "Bad password" iodine_info`
  `rm iodine_info`
  if iodine_setup_output =~ /Bad password/ then
    error_colour
    puts "ERROR: The password provided is incorrect."
    reset_colour
    exit 1
  end
  print "--> discovering settings"
  config = get_config
  # TODO: Do something with the settings!
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

def autodiscover_settings paras
  connect_with_iodine paras
end

puts `clear`
welcome
paras = get_info
autodiscover_settings paras
# start_real_work;
