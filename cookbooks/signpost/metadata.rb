maintainer        "Signpost team"
maintainer_email  "sebastian.probst.eide@gmail.com"
license           "Apache 2.0"
description       "Installs the signpost server application"
version           "0.0.1"
recipe            "signpost", "Installs the signpost application"

%w{ ubuntu debian arch}.each do |os|
  supports os
end

%w{ ntp git bluepill ocaml ocaml::signpost openvswitch }.each do |cb|
  depends cb
end
